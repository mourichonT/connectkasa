import 'package:cloud_firestore/cloud_firestore.dart';

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
          .collection("Residence")
          .doc(residenceId)
          .collection("documents_copro")
          .add(data);

      print("✅ Document ajouté avec succès !");
    } catch (e) {
      print("❌ Erreur lors de l'ajout du document : $e");
      rethrow;
    }
  }

  static Future<void> submitFormIndividuel({
    required List<String> uid,
    required String refLot,
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
    };

    try {
      for (String userId in uid) {
        await FirebaseFirestore.instance
            .collection("User")
            .doc(userId)
            .collection("lots")
            .doc(refLot)
            .collection("documents")
            .add(data);
      }

      print("✅ Document ajouté avec succès pour tous les destinataires !");
    } catch (e) {
      print("❌ Erreur lors de l'ajout du document : $e");
      rethrow;
    }
  }
}
