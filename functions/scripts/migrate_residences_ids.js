/**
 * Migration one-off : reconstruit User/{uid}.residencesIds et
 * User/{uid}.sharedWithLandlords sur TOUS les utilisateurs existants, à
 * partir de leurs sous-collections User/{uid}/lots et des lots
 * Residence/{residenceId}/lot/{lotId} correspondants.
 *
 * Pourquoi : firestore.rules s'appuie sur ces deux champs dénormalisés pour
 * savoir si un utilisateur appartient à une résidence (isResidenceMember)
 * ou consulte légitimement le dossier d'un locataire (isSharedTenantDoc).
 * Les comptes créés avant l'introduction de cette dénormalisation
 * (databases_user_services.dart / databases_lot_services.dart) n'ont pas
 * encore ces champs — sans cette migration, ils perdent l'accès à leurs
 * propres données dès l'activation des règles strictes.
 *
 * NE PAS exécuter automatiquement : ce script écrit sur les données de
 * production. À lancer manuellement, une seule fois, avant le déploiement
 * de firestore.rules (et après avoir déployé les changements Dart qui
 * maintiennent ces champs pour les écritures futures).
 *
 * Prérequis :
 *   - Un compte de service avec accès Firestore sur le projet, référencé
 *     via la variable d'environnement GOOGLE_APPLICATION_CREDENTIALS, ou
 *     `gcloud auth application-default login` exécuté au préalable.
 *
 * Utilisation :
 *   cd functions
 *   node scripts/migrate_residences_ids.js            // dry-run (aucune écriture, affiche ce qui serait fait)
 *   node scripts/migrate_residences_ids.js --apply     // écrit réellement
 */

const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const APPLY = process.argv.includes("--apply");

async function migrate() {
  console.log(APPLY ? "Mode APPLY (écriture réelle)" : "Mode DRY-RUN (aucune écriture)");

  const usersSnapshot = await db.collection("User").get();
  console.log(`Utilisateurs trouvés : ${usersSnapshot.size}`);

  let updated = 0;
  let skipped = 0;

  for (const userDoc of usersSnapshot.docs) {
    const uid = userDoc.id;
    const userLotsSnapshot = await db
        .collection("User")
        .doc(uid)
        .collection("lots")
        .get();

    if (userLotsSnapshot.empty) {
      skipped++;
      continue;
    }

    const residenceIds = new Set();
    const landlordUids = new Set();

    for (const userLotDoc of userLotsSnapshot.docs) {
      const lotId = userLotDoc.id;
      const residenceId = userLotDoc.data().residenceId;
      if (!residenceId) continue;

      residenceIds.add(residenceId);

      const lotSnapshot = await db
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .doc(lotId)
          .get();

      if (!lotSnapshot.exists) continue;

      const lotData = lotSnapshot.data();
      const idLocataire = Array.isArray(lotData.idLocataire) ? lotData.idLocataire : [];
      const idProprietaire = Array.isArray(lotData.idProprietaire) ? lotData.idProprietaire : [];

      if (idLocataire.includes(uid)) {
        idProprietaire.forEach((landlordUid) => landlordUids.add(landlordUid));
      }
    }

    const residencesIdsList = Array.from(residenceIds);
    const sharedWithLandlordsList = Array.from(landlordUids);

    console.log(
        `User/${uid} -> residencesIds=${JSON.stringify(residencesIdsList)} ` +
        `sharedWithLandlords=${JSON.stringify(sharedWithLandlordsList)}`,
    );

    if (APPLY) {
      await db.collection("User").doc(uid).set({
        residencesIds: residencesIdsList,
        sharedWithLandlords: sharedWithLandlordsList,
      }, {merge: true});
    }

    updated++;
  }

  console.log(`Terminé. ${updated} utilisateur(s) traité(s), ${skipped} ignoré(s) (aucun lot).`);
  if (!APPLY) {
    console.log("Dry-run seulement — relancer avec --apply pour écrire réellement.");
  }
}

migrate()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("Erreur pendant la migration :", err);
      process.exit(1);
    });
