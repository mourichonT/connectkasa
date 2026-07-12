import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/utils/app_logger.dart';

class SubmitDocController {
  static Future<void> submitFormCopro({
    required String residenceId,
    required String docExtension,
    required String docName,
    required String category,
    required String docPath,
  }) async {
    // Exemple de payload à envoyer à Firestore ou autre service
    final Map<String, dynamic> data = {
      "name": docName,
      "type": category,
      "extension": docExtension,
      "documentPathRecto": docPath,
      "timeStamp": Timestamp.now()
    };

    try {
      // Exemple avec Firebase Firestore
      await FirebaseFirestore.instance
          .collection("residences")
          .doc(residenceId)
          .collection("documents_copro")
          .add(data);

      appLog("✅ Document ajouté avec succès !");
    } catch (e) {
      appLog("❌ Erreur lors de l'ajout du document : $e");
      rethrow;
    }
  }

  static Future<void> submitFormIndividuel({
    required List<String> uid,
    required String lotId,
    required String residenceId,
    required String docExtension,
    required String docName,
    required String category,
    required String docPath,
  }) async {
    // Exemple de payload à envoyer à Firestore
    final Map<String, dynamic> data = {
      "name": docName,
      "type": category,
      "extension": docExtension,
      "documentPathRecto": docPath,
      "timeStamp": Timestamp.now(),
      // Liste des vrais destinataires (lue par deleteDocument() pour ne
      // nettoyer que les copies réellement déposées, pas tous les membres
      // actuels du lot - certains peuvent avoir été révoqués depuis, ou
      // n'avoir jamais reçu ce document précis).
      "destinataire": uid,
    };

    try {
      // Même ID de document chez chaque destinataire (généré une seule
      // fois, puis .set() au lieu de .add() par destinataire) : nécessaire
      // pour que deleteDocument() (my_docs.dart), qui supprime "ce
      // documentId" chez tous les destinataires d'un coup, cible bien le
      // même document partout au lieu d'IDs auto-générés indépendamment.
      final documentId = FirebaseFirestore.instance
          .collection("users")
          .doc(uid.first)
          .collection("lots")
          .doc(lotId)
          .collection("documents")
          .doc()
          .id;

      for (String userId in uid) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("lots")
            .doc(lotId)
            .collection("documents")
            .doc(documentId)
            .set(data);
      }

      appLog("✅ Document ajouté avec succès pour tous les destinataires !");
    } catch (e) {
      appLog("❌ Erreur lors de l'ajout du document : $e");
      rethrow;
    }
  }
}
