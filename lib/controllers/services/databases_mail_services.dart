import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';

class DatabasesMailServices {
  Future<List<Mail>> getMailFromUid(String uid) async {
    List<Mail> mailsFromUid = [];

    try {
      // Récupérer les documents de la collection "mail" depuis Firestore
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('mail')
              .where('message.subject',
                  isEqualTo: "Message d'un utilisateur ref : $uid")
              .get();

      // Parcourir les documents et les convertir en objets Mail
      for (QueryDocumentSnapshot<Map<String, dynamic>> docSnapshot
          in querySnapshot.docs) {
        // Convertir le document en Map
        Map<String, dynamic> data = docSnapshot.data();

        // Créer un objet Mail à partir des données
        Mail mail = Mail.fromJson(data);

        // Ajouter le mail à la liste
        mailsFromUid.add(mail);
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
}
