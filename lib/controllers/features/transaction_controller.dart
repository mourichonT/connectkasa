import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionController {
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
}
