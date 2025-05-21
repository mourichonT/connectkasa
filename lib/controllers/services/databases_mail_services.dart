import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';

class DatabasesMailServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMail(
      String uid, Lot selectedLot, List<String> accountantMail) {
    return db
        .collection('mail')
        .where('message.subject',
            isEqualTo:
                "Vous avez un message pour la residence ${selectedLot.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}")
        .where(Filter.or(
          Filter('to', isEqualTo: accountantMail),
          Filter('from', isEqualTo: accountantMail.first),
        ))
        //Filter('from', isEqualTo: accountantMail.first),
        .orderBy("delivery.startTime", descending: false) // Trie par startTime
        .snapshots();
  }

  Future<List<Mail>> getMailFromUid(
      String uid, Lot selectedLot, String accountantMail) async {
    List<Mail> mailsFromUid = [];

    try {
      // Récupérer les documents de la collection "mail" depuis Firestore
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection('mail')
          .where('message.subject',
              isEqualTo:
                  "Vous avez un message pour la residence ${selectedLot.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}")
          .orderBy("delivery.startTime",
              descending: false) // Trie par startTime
          .get();

      // Parcourir les documents et les convertir en objets Mail
      for (QueryDocumentSnapshot<Map<String, dynamic>> docSnapshot
          in querySnapshot.docs) {
        dynamic from = docSnapshot.data()["from"];
        dynamic to = docSnapshot.data()["to"];

        if ((to is List && to.contains(accountantMail)) ||
            (from is String && from == accountantMail)) {
          // Convertir le document en Map
          //  Map<String, dynamic> data = docSnapshot.data();
          print("je suis dans la condition IF");
          // Créer un objet Mail à partir des données
          Mail mail = Mail.fromJson(docSnapshot.data());

          // Ajouter le mail à la liste
          mailsFromUid.add(mail);
        }
      }

      // Retourner la liste des mails
      return mailsFromUid;
    } catch (e) {
      // Gérer l'erreur ici
      print('Une erreur s\'est produite lors de la récupération des mails: $e');
      // Vous pouvez choisir de renvoyer une liste vide ou de lancer l'erreur
      throw Exception('Impossible de récupérer les mails');
    }
  }

  Future<void> sendMail(
      {String? subject,
      Lot? selectedLot,
      String? residenceId,
      required String message,
      required List<String> receiverId}) async {
    final Timestamp timestamp = Timestamp.now();

    Mail newMessage = Mail(
        to: receiverId,
        startTime: timestamp,
        subject: subject ??
            "Vous avez un message pour la residence ${selectedLot!.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}",
        html: message);
    await db
        .collection("Residence")
        .doc(residenceId ?? selectedLot!.residenceId)
        .collection("mail")
        .add(newMessage.toJson());
  }
}
