
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';

class TransactionServices {
  // UID du portefeuille général de l'application
  static const String _walletUid = "0hR1IOPOcuTujkZTOP6Bwuqa3K13";

  static Future<bool> effectuerTransaction(
      {required String idUserEmetteur,
      required String idUserReceveur,
      required String montant,
      required String fees}) async {
    try {
      final db = FirebaseFirestore.instance;

      // Les transactions Firestore ne supportent pas les queries — on récupère
      // les références avant, puis on relit dans la transaction pour la cohérence.
      final emetteurSnapshot = await db
          .collection("User")
          .where("uid", isEqualTo: idUserEmetteur)
          .limit(1)
          .get();
      final receveurSnapshot = await db
          .collection("User")
          .where("uid", isEqualTo: idUserReceveur)
          .limit(1)
          .get();
      final walletSnapshot = await db
          .collection("User")
          .where("uid", isEqualTo: _walletUid)
          .limit(1)
          .get();

      if (emetteurSnapshot.docs.isEmpty ||
          receveurSnapshot.docs.isEmpty ||
          walletSnapshot.docs.isEmpty) {
        throw Exception('Utilisateur introuvable');
      }

      final emetteurRef = emetteurSnapshot.docs.first.reference;
      final receveurRef = receveurSnapshot.docs.first.reference;
      final walletRef = walletSnapshot.docs.first.reference;
      final montantD = double.parse(montant);
      final feesD = double.parse(fees);

      await db.runTransaction((txn) async {
        final emetteurDoc = await txn.get(emetteurRef);
        final receveurDoc = await txn.get(receveurRef);
        final walletDoc = await txn.get(walletRef);

        final soldeCourantEmetteur = double.parse(emetteurDoc.get('solde'));
        if (soldeCourantEmetteur < montantD) {
          throw Exception('Transaction impossible, les fonds sont insuffisants');
        }

        txn.update(emetteurRef,
            {'solde': (soldeCourantEmetteur - montantD).toString()});
        txn.update(receveurRef, {
          'solde':
              (double.parse(receveurDoc.get('solde')) + montantD).toString()
        });
        txn.update(walletRef, {
          'solde': (double.parse(walletDoc.get('solde')) + feesD).toString()
        });
      });

      return true;
    } catch (e) {
      print('Erreur lors de la transaction : $e');
      return false;
    }
  }

  Future<List<TransactionModel>> getTransactionByUid(
      String uid, String residenceId) async {
    List<TransactionModel> transactions = [];
    try {
      // Accéder à la collection "transactions" dans Firestore
      QuerySnapshot querySnapshotAcheteur = await FirebaseFirestore.instance
          .collection('transaction')
          .where("residenceId", isEqualTo: residenceId)
          .where('uidAcheteur', isEqualTo: uid)
          .get();

      QuerySnapshot querySnapshotVendeur = await FirebaseFirestore.instance
          .collection('transaction')
          .where("residenceId", isEqualTo: residenceId)
          .where('uidVendeur', isEqualTo: uid)
          .get();

      // Parcourir chaque document dans le QuerySnapshot pour les acheteurs
      for (var doc in querySnapshotAcheteur.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentReference'] = doc.reference;
        TransactionModel transaction = TransactionModel.fromJson(data);
        transactions.add(transaction);
      }

      // Parcourir chaque document dans le QuerySnapshot pour les vendeurs
      for (var doc in querySnapshotVendeur.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentReference'] = doc.reference;
        TransactionModel transaction = TransactionModel.fromJson(data);
        transactions.add(transaction);
      }

      // Retourner la liste des transactions récupérées
      return transactions;
    } catch (e) {
      // Gérer les erreurs
      print("Erreur lors de la récupération des transactions : $e");
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  static Future<TransactionModel> createdTransac({
    required String uidFrom,
    required String uidTo,
    required String amount,
    required String fees,
    required String residenceId,
    required Post post,
  }) async {
    String uniqueId =
        FirebaseFirestore.instance.collection('transactions').doc().id;
    // Créez une instance de la transaction
    TransactionModel transaction = TransactionModel(
        amount: amount,
        fees: fees,
        uidAcheteur: uidFrom,
        uidVendeur: uidTo,
        statut: 'en attente', // Statut initial de la transaction
        postId: post.id,
        residenceId: residenceId,
        validationDate: Timestamp.now(),
        id: uniqueId);

    // Ajoutez la transaction à Firestore
    await FirebaseFirestore.instance
        .collection('transaction')
        .add(transaction.toJson());

    // Retourner l'instance de la transaction
    return transaction;
  }

  static Future<void> updatePaymentDate(
      {required String transactionId, required bool isClosed}) async {
    try {
      Timestamp paymentDate = Timestamp.now();

      // Query to find the document(s) where the transactionId matches
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('transaction')
          .where('id', isEqualTo: transactionId)
          .get();
      if (isClosed) {
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          await doc.reference
              .update({'paymentDate': paymentDate, 'statut': "Terminé"});
          print('Payment date updated successfully');
        }
      } else {
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          await doc.reference
              .update({'paymentDate': paymentDate, 'statut': "Annulé"});
          print('Payment  updated canceled');
        }
      }

      // Iterate through the results and update the paymentDate field for each document
    } catch (e) {
      print('Failed to update payment date: $e');
    }
  }
}
