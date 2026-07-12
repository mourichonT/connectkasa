const {onDocumentCreated} = require("firebase-functions/v2/firestore");
// onDelete (nettoyage après suppression de compte) n'existe qu'en v1 :
// firebase-functions v7 embarque toujours ce sous-module pour compatibilité.
const functionsV1 = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Supprime récursivement tous les fichiers Storage sous un préfixe donné.
 * @param {string} prefix Préfixe de chemin Storage (ex: "user/uid123/").
 * @return {Promise<void>}
 */
async function deleteStorageFolder(prefix) {
  try {
    await admin.storage().bucket().deleteFiles({prefix});
  } catch (error) {
    console.error(`Erreur suppression Storage ${prefix} :`, error);
  }
}

/**
 * Renvoie le token FCM d'un utilisateur, sauf s'il a désactivé le type de
 * notification demandé (users/{uid}.notificationPrefs.<type>, opt-out : une
 * clé absente ou à `true` autorise l'envoi, seule une valeur explicite
 * `false` le bloque). Voir NotificationType
 * (lib/models/enum/notification_type.dart) côté Flutter pour la liste
 * des clés possibles.
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @param {string} type Clé de notificationPrefs (ex: "message", "sinistres").
 * @return {Promise<string|null>}
 */
async function getTokenIfNotificationAllowed(db, uid, type) {
  try {
    const [tokenDoc, userDoc] = await Promise.all([
      db.collection("users").doc(uid).collection("private").doc("fcm").get(),
      db.collection("users").doc(uid).get(),
    ]);

    if (!tokenDoc.exists || !tokenDoc.data().token) return null;

    const prefs = (userDoc.exists && userDoc.data().notificationPrefs) || {};
    if (prefs[type] === false) return null;

    return tokenDoc.data().token;
  } catch (error) {
    console.error(`Erreur récupération token pour uid ${uid} :`, error);
    return null;
  }
}

/**
 * Nettoyage complet des données Firestore/Storage d'un utilisateur supprimé.
 * Équivalent, côté Admin SDK (bypass firestore.rules), de l'ancien
 * DataBasesUserServices.purgeUserData() côté client — devenu impossible à
 * exécuter depuis le client une fois le compte Firebase Auth supprimé
 * (request.auth devient null, donc plus aucune règle Firestore n'autorise
 * ces écritures). Se déclenche automatiquement à la suppression du compte
 * Auth, quel que soit le flux qui l'a déclenchée (suppression volontaire de
 * compte, ou abandon d'inscription en cours de route).
 */
exports.cleanupUserData = functionsV1.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const db = admin.firestore();

  console.log(`cleanupUserData: début pour ${uid}`);

  // 'User/{uid}' est nettoyé en plus de 'user/{uid}' à cause d'une
  // incohérence de casse côté client (docu_justif_upload_widget.dart
  // utilisait 'User' au lieu de 'user').
  await deleteStorageFolder(`user/${uid}/`);
  await deleteStorageFolder(`User/${uid}/`);

  // Retire l'utilisateur du conseil syndical de toutes les résidences où il
  // siège.
  try {
    const residencesSnapshot = await db
        .collection("residences")
        .where("csmembers", "array-contains", uid)
        .get();

    for (const residenceDoc of residencesSnapshot.docs) {
      await residenceDoc.ref.update({
        csmembers: admin.firestore.FieldValue.arrayRemove(uid),
      });
      console.log(`csmembers : ${uid} retiré de ${residenceDoc.id}`);
    }
  } catch (error) {
    console.error("Erreur retrait csmembers :", error);
  }

  // Lit users/{uid}/lots une seule fois : sert à la fois à retirer
  // l'utilisateur de idProprietaire/idLocataire sur chaque lot, et à savoir
  // dans quelles résidences chercher ses annonces à supprimer.
  let userLotsDocs = [];
  try {
    const userLotsSnapshot = await db
        .collection("users")
        .doc(uid)
        .collection("lots")
        .get();
    userLotsDocs = userLotsSnapshot.docs;
  } catch (error) {
    console.error("Erreur lecture User/lots :", error);
  }

  const residenceIds = new Set(
      userLotsDocs
          .map((doc) => doc.data().residenceId)
          .filter((id) => typeof id === "string"),
  );

  for (const userLotDoc of userLotsDocs) {
    const residenceId = userLotDoc.data().residenceId;
    const lotId = userLotDoc.id;
    if (!residenceId) continue;

    try {
      const lotRef = db
          .collection("residences")
          .doc(residenceId)
          .collection("lots")
          .doc(lotId);
      const lotSnapshot = await lotRef.get();
      if (!lotSnapshot.exists) continue;

      const lotData = lotSnapshot.data();
      const updates = {};

      const idLocataire = Array.isArray(lotData.idLocataire) ?
        lotData.idLocataire : [];
      const idProprietaire = Array.isArray(lotData.idProprietaire) ?
        lotData.idProprietaire : [];

      if (idLocataire.includes(uid)) {
        updates.idLocataire = admin.firestore.FieldValue.arrayRemove(uid);
      }
      if (idProprietaire.includes(uid)) {
        updates.idProprietaire = admin.firestore.FieldValue.arrayRemove(uid);
      }

      if (Object.keys(updates).length > 0) {
        await lotRef.update(updates);
        console.log(`lot ${residenceId}/${lotId} : ${uid} retiré`);
      }
    } catch (error) {
      console.error(`Erreur retrait lot ${residenceId}/${lotId} :`, error);
    }
  }

  // Supprime les posts de type "annonces" créés par l'utilisateur, dans les
  // résidences auxquelles il est lié, ainsi que le dossier Storage complet
  // de chaque annonce (residences/{residenceId}/annonces/{post.id}/).
  for (const residenceId of residenceIds) {
    try {
      const postsSnapshot = await db
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("user", "==", uid)
          .where("type", "==", "annonces")
          .get();

      for (const postDoc of postsSnapshot.docs) {
        // post.id (champ métier) sert de nom de sous-dossier Storage,
        // distinct de postDoc.id (id auto-généré Firestore, addPost
        // utilisant .add()).
        const postId = postDoc.data().id || postDoc.id;
        await postDoc.ref.delete();
        await deleteStorageFolder(
            `residences/${residenceId}/annonces/${postId}/`,
        );
        console.log(`annonce ${postId} supprimée (résidence ${residenceId})`);
      }
    } catch (error) {
      console.error(`Erreur suppression annonces (${residenceId}) :`, error);
    }
  }

  // Supprime le document users/{uid} et TOUTES ses sous-collections en une
  // fois (documents, demandes_loc, lots + leurs documents, profil_locataire
  // + garants + leurs documents).
  try {
    await db.recursiveDelete(db.collection("users").doc(uid));
    console.log(`User/${uid} et ses sous-collections supprimés`);
  } catch (error) {
    console.error(`Erreur suppression User/${uid} :`, error);
  }

  console.log(`cleanupUserData: terminé pour ${uid}`);
});

exports.notifyNewPost = onDocumentCreated(
    // region alignée avec la localisation de la base Firestore (eur3) :
    // sans ça, le trigger Eventarc (créé dans la région de la base) doit
    // relayer chaque événement vers us-central1 (région par défaut),
    // un saut réseau inter-région inutile à chaque nouveau post.
    {
      document: "residences/{residenceId}/posts/{postId}",
      region: "europe-west1",
    },
    async (event) => {
      const snapshot = event.data;
      const db = admin.firestore();
      const messaging = admin.messaging();

      const residenceId = event.params.residenceId;
      const postData = snapshot.data();

      // Étape 1 : récupérer les UIDs des utilisateurs de la résidence
      let users = [];
      try {
        console.log("DEBUT DE LA FONCTION NOTIFICATION");
        console.log("__________________________________");
        const lotsSnapshot = await db
            .collection("residences")
            .doc(residenceId)
            .collection("lots")
            .get();

        lotsSnapshot.forEach((lotDoc) => {
          const lotData = lotDoc.data();
          const idLocataire = Array.isArray(lotData.idLocataire) ?
          lotData.idLocataire :
          [];
          const idProprietaire = Array.isArray(lotData.idProprietaire) ?
          lotData.idProprietaire :
          [];

          users.push(...idLocataire);
          idProprietaire.forEach((proprietaireId) => {
            if (!idLocataire.includes(proprietaireId)) {
              users.push(proprietaireId);
            }
          });
        });

        users = [...new Set(users)];
        console.log("Utilisateurs récupérés pour la résidence :", users);
      } catch (error) {
        console.error("Erreur récupération lots :", error);
        return null;
      }

      if (users.length === 0) {
        console.log("Aucun utilisateur trouvé dans la résidence.");
        return null;
      }

      // Étape 2 : récupérer les tokens FCM des utilisateurs individuellement,
      // en excluant ceux qui ont désactivé les notifications pour ce type de
      // publication (notificationPrefs sur users/{uid}). Lectures
      // parallélisées (Promise.all) plutôt qu'une boucle séquentielle : pour
      // une résidence de N résidents, N lectures en parallèle au lieu de N
      // lectures l'une après l'autre. Chaque promesse gère sa propre erreur
      // (renvoie null) pour qu'un token en échec ne fasse pas échouer
      // Promise.all() pour tout le monde.
      users = users.filter(
          (uid) => typeof uid === "string" &&
        uid.trim() !== "");
      const tokens = (await Promise.all(
          users.map((uid) =>
            getTokenIfNotificationAllowed(db, uid, postData.type)),
      )).filter((token) => !!token);

      if (tokens.length === 0) {
        console.log("Aucun token FCM disponible.");
        return null;
      }

      // Étape 3 & 4 : Construire la notification et envoyer avec
      // sendEachForMulticast
      const message = {
        notification: {
          title: `Un résident a publié dans votre copropriété`,
          body: postData.titre || "Nouvelle publication dans la résidence.",
        },
        data: {
          type: postData.type || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {priority: "high"},
        apns: {headers: {"apns-priority": "10"}},
      };


      try {
        console.log("Message:", message );
        const response =
            await messaging.sendEachForMulticast({
              tokens,
              notification: message.notification,
              data: message.data,
              android: message.android,
              apns: message.apns,
            });
        console.log(
            `Notifications envoyées: ${response.successCount} réussies, 
            ${response.failureCount} échouées.`,
        );
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.error(`Erreur envoi token ${tokens[idx]}:`, resp.error);
            }
          });
        }
        return null;
      } catch (error) {
        console.error("Erreur envoi notification:", error);
        return null;
      }
    },
);

exports.notifyNewMessage = onDocumentCreated(
    // region alignée avec la localisation de la base Firestore (eur3),
    // voir commentaire sur notifyNewPost.
    {
      document: "residences/{residenceId}/chats/{chatId}/messages/{messageId}",
      region: "europe-west1",
    },
    async (event) => {
      const messaging = admin.messaging();
      const db = admin.firestore();
      const snapshot = event.data;
      const message = snapshot.data();

      if (
        !message ||
      !message.userIdFrom ||
      !message.userIdTo ||
      !message.message
      ) {
        console.log("Champs requis manquants dans le message :", message);
        return null;
      }

      try {
        const senderDoc = await db.collection("users")
            .doc(message.userIdFrom).get();
        const receiverToken = await getTokenIfNotificationAllowed(
            db, message.userIdTo, "message");

        if (!receiverToken) {
          console.log(
              "Token FCM manquant ou notifications désactivées " +
            "pour le destinataire.");
          return null;
        }

        // ✅ Construction du nom de l’expéditeur de manière robuste
        const senderData = senderDoc.data() || {};
        const senderName = senderData.pseudo ?
        `de ${senderData.pseudo}` :
        senderData.name && senderData.surname ?
            `de ${senderData.name} ${senderData.surname}` :
            "d'un voisin";


        const chatId = event.params.chatId;
        const payload = {
          notification: {
            title: `Nouveau message ${senderName}`,
            body: message.message,
          },
          data: {
            type: "message", // 🔁 Sert à filtrer côté Flutter
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            residenceId: event.params.residenceId,
            idUserFrom: message.userIdTo,
            idUserTo: message.userIdFrom,
            chatId: chatId,

          },
          token: receiverToken,
          android: {priority: "high"},
          apns: {headers: {"apns-priority": "10"}},
        };


        await messaging.send(payload);
        console.log("Notification envoyée à", message.userIdTo);
        return null;
      } catch (error) {
        console.error("Erreur dans notifyNewMessage :", error);
        return null;
      }
    },


);


exports.notifyDemandeLoc = onDocumentCreated(
    // region alignée avec la localisation de la base Firestore (eur3),
    // voir commentaire sur notifyNewPost.
    {
      document: "users/{proprietaireUid}/demandes_loc/{demandeId}",
      region: "europe-west1",
    },
    async (event) => {
      const snapshot = event.data;
      const demandeData = snapshot.data();
      const db = admin.firestore();
      const messaging = admin.messaging();

      const proprietaireUid = event.params.proprietaireUid;

      if (!demandeData || !demandeData.tenantId) {
        console.log("Données de demande incomplètes :", demandeData);
        return null;
      }

      try {
        const token = await getTokenIfNotificationAllowed(
            db, proprietaireUid, "demande_loc");

        if (!token) {
          console.log(
              "Token FCM manquant ou notifications désactivées " +
            "pour le propriétaire.");
          return null;
        }

        const notificationPayload = {
          notification: {
            title: "Nouvelle demande de location",
            body: `Vous avez reçu une nouvelle demande 
            de location pour l'un de vos biens`,
          },
          data: {
            type: "demande_loc",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            tenantId: demandeData.tenantId,
            senderUid: event.params.proprietaireUid,
          },
          token,
          android: {priority: "high"},
          apns: {headers: {"apns-priority": "10"}},
        };

        await messaging.send(notificationPayload);
        console.log("Notification envoyée au propriétaire :", proprietaireUid);
        return null;
      } catch (error) {
        console.error("Erreur lors de l'envoi de la notification :", error);
        return null;
      }
    },
);


