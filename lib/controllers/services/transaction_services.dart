import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';

class TransactionServices {
  static Future<bool> effectuerTransaction(
      String idUserEmetteur, String idUserReceveur, String montant) async {
    try {
      // Récupérez les références des documents des utilisateurs émetteur et receveur
      Query<Map<String, dynamic>> emetteurQuery = FirebaseFirestore.instance
          .collection("User")
          .where("uid", isEqualTo: idUserEmetteur)
          .limit(1);

      Query<Map<String, dynamic>> receveurQuery = FirebaseFirestore.instance
          .collection("User")
          .where("uid", isEqualTo: idUserReceveur)
          .limit(1);

      QuerySnapshot<Map<String, dynamic>> emetteurSnapshot =
          await emetteurQuery.get();
      QuerySnapshot<Map<String, dynamic>> receveurSnapshot =
          await receveurQuery.get();

      if (emetteurSnapshot.docs.isEmpty ||
          receveurSnapshot.docs.isEmpty ||
          double.parse(emetteurSnapshot.docs.first['solde']) <
              double.parse(montant)) {
        throw Exception('Transaction impossible, les fonds sont insuffisants');
      }

      DocumentReference emetteurRef = emetteurSnapshot.docs.first.reference;
      DocumentReference receveurRef = receveurSnapshot.docs.first.reference;

      double nouveauSoldeEmetteur =
          double.parse(emetteurSnapshot.docs.first['solde']) -
              double.parse(montant);
      double nouveauSoldeReceveur =
          double.parse(receveurSnapshot.docs.first['solde']) +
              double.parse(montant);

      await emetteurRef.update({'solde': nouveauSoldeEmetteur.toString()});
      await receveurRef.update({'solde': nouveauSoldeReceveur.toString()});

      // La transaction a réussi
      return true;
    } catch (e) {
      // Une erreur s'est produite lors de la transaction
      print('Erreur lors de la transaction : $e');
      return false;
    }
  }

  Future<List<TransactionModel>> getTransactionByUid(
      String uidAcheteur, String residenceId) async {
    List<TransactionModel> transactions = [];
    try {
      // Accéder à la collection "transactions" dans Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('transaction') // Correction du nom de la collection
          .where("residenceId", isEqualTo: residenceId)
          .where('uidAcheteur', isEqualTo: uidAcheteur)
          .get();

      // Liste pour stocker les transactions récupérées

      // Parcourir chaque document dans le QuerySnapshot
      querySnapshot.docs.forEach((doc) {
        // Accéder aux données du document
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Ajouter la référence du document à l'objet TransactionModel
        data['documentReference'] = doc.reference;
        // Créer une instance de Transaction à partir des données du document
        TransactionModel transaction = TransactionModel.fromJson(data);
        // Ajouter la transaction à la liste
        transactions.add(transaction);
      });

      // Retourner la liste des transactions récupérées
      return transactions;
    } catch (e) {
      // Gérer les erreurs
      print("Erreur lors de la récupération des transactions : $e");
      return []; // Retourner une liste vide en cas d'erreur
    }
  }
}
