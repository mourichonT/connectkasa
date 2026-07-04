import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';

class DatabasesMailServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMail(
      String uid, Lot selectedLot, List<String> accountantMail) {
    // Residence/{id}/mail, pas la collection racine 'mail' : sendMail()
    // écrit ici depuis la migration du scoping par résidence (voir
    // firestore.rules), la collection racine ne reçoit plus rien depuis.
    return db
        .collection("Residence")
        .doc(selectedLot.residenceId)
        .collection('mail')
        .where('message.subject',
            isEqualTo:
                "Vous avez un message pour la residence ${selectedLot.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}")
        .where(Filter.or(
          Filter('to', isEqualTo: accountantMail),
          Filter('from', isEqualTo: accountantMail.first),
        ))
        //Filter('from', isEqualTo: accountantMail.first),
        .orderBy("startTime", descending: false) // Trie par startTime
        .snapshots();
  }

  Future<List<Mail>> getMailFromUid(
      String uid, Lot selectedLot, String accountantMail) async {
    List<Mail> mailsFromUid = [];

    try {
      // Residence/{id}/mail, pas la collection racine 'mail' : sendMail()
      // écrit ici depuis la migration du scoping par résidence (voir
      // firestore.rules), la collection racine ne reçoit plus rien depuis.
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(selectedLot.residenceId)
          .collection('mail')
          .where('message.subject',
              isEqualTo:
                  "Vous avez un message pour la residence ${selectedLot.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}")
          .orderBy("startTime", descending: false) // Trie par startTime
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
    final String targetResidenceId = residenceId ?? selectedLot!.residenceId;
    final String mailSubject = subject ??
        "Vous avez un message pour la residence ${selectedLot!.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}";

    Mail newMessage = Mail(
        to: receiverId,
        startTime: timestamp,
        subject: mailSubject,
        html: message);

    final residenceRef = db.collection("Residence").doc(targetResidenceId);

    // La Cloud Function send_email_on_create écoute la création de documents
    // dans Residence/{id}/mail (from == null) pour déclencher l'envoi SMTP
    // réel en plus de l'affichage dans le fil in-app.
    await residenceRef.collection("mail").add(newMessage.toJson());
  }
}
