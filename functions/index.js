const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyNewPost = onDocumentCreated(
    {document: "Residence/{residenceId}/post/{postId}"},
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
            .collection("Residence")
            .doc(residenceId)
            .collection("lot")
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

      // Étape 2 : récupérer les tokens FCM des utilisateurs individuellement
      users = users.filter(
          (uid) => typeof uid === "string" &&
        uid.trim() !== "");
      const tokens = [];

      for (const uid of users) {
        try {
          const userDoc = await db.collection("User").doc(uid).get();
          if (userDoc.exists) {
            const userData = userDoc.data();
            if (userData && userData.token) {
              tokens.push(userData.token);
              tokens;
            }
          }
        } catch (error) {
          console.error(`Erreur récupération token pour uid ${uid} :`, error);
        }
      }

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
    {document: "Residence/{residenceId}/chat/{chatId}/messages/{messageId}"},
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
        const senderDoc = await db.collection("User")
            .doc(message.userIdFrom).get();
        const receiverDoc = await db.collection("User")
            .doc(message.userIdTo).get();

        if (!receiverDoc.exists || !receiverDoc.data().token) {
          console.log("Token FCM manquant pour le destinataire.");
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
          token: receiverDoc.data().token,
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
    {document: "User/{proprietaireUid}/demandes_loc/{demandeId}"},
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
        const userDoc = await db.collection("User").doc(proprietaireUid).get();

        if (!userDoc.exists || !userDoc.data().token) {
          console.log("Token FCM manquant pour le propriétaire.");
          return null;
        }

        const token = userDoc.data().token;

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


