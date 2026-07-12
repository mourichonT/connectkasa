import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/mail_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/mail.dart';

class FirestoreMailRepository implements IMailRepository {
  final FirebaseFirestore _firestore;

  FirestoreMailRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<Result<QuerySnapshot>> getMail(
      String uid, Lot selectedLot, List<String> accountantMail) {
    // residences/{id}/mail, pas la collection racine 'mail' : sendMail()
    // écrit ici depuis la migration du scoping par résidence (voir
    // firestore.rules), la collection racine ne reçoit plus rien depuis.
    return _firestore
        .collection("residences")
        .doc(selectedLot.residenceId)
        .collection('mail')
        .where('message.subject',
            isEqualTo:
                "Vous avez un message pour la residence ${selectedLot.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}")
        .where(Filter.or(
          Filter('to', isEqualTo: accountantMail),
          Filter('from', isEqualTo: accountantMail.first),
        ))
        .orderBy("startTime", descending: false)
        .snapshots()
        .map<Result<QuerySnapshot>>((snapshot) => Result.success(snapshot))
        .handleError(
            (Object e) => Result<QuerySnapshot>.failure(AppException.from(e)));
  }

  @override
  Future<Result<List<Mail>>> getMailFromUid(
      String uid, Lot selectedLot, String accountantMail) async {
    try {
      // residences/{id}/mail, pas la collection racine 'mail' : sendMail()
      // écrit ici depuis la migration du scoping par résidence (voir
      // firestore.rules), la collection racine ne reçoit plus rien depuis.
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(selectedLot.residenceId)
          .collection('mail')
          .where('message.subject',
              isEqualTo:
                  "Vous avez un message pour la residence ${selectedLot.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}")
          .orderBy("startTime", descending: false)
          .get();

      final mailsFromUid = <Mail>[];
      for (final docSnapshot in querySnapshot.docs) {
        final from = docSnapshot.data()["from"];
        final to = docSnapshot.data()["to"];

        if ((to is List && to.contains(accountantMail)) ||
            (from is String && from == accountantMail)) {
          mailsFromUid.add(Mail.fromJson(docSnapshot.data()));
        }
      }

      return Result.success(mailsFromUid);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> sendMail({
    String? subject,
    Lot? selectedLot,
    String? residenceId,
    required String message,
    required List<String> receiverId,
  }) async {
    try {
      final Timestamp timestamp = Timestamp.now();
      final String targetResidenceId = residenceId ?? selectedLot!.residenceId;
      final String mailSubject = subject ??
          "Vous avez un message pour la residence ${selectedLot!.residenceData['name']} - lot ${selectedLot.batiment} ${selectedLot.lot}";

      final newMessage = Mail(
        to: receiverId,
        startTime: timestamp,
        subject: mailSubject,
        html: message,
      );

      final residenceRef = _firestore.collection("residences").doc(targetResidenceId);

      // La Cloud Function send_email_on_create écoute la création de
      // documents dans residences/{id}/mail (from == null) pour déclencher
      // l'envoi SMTP réel en plus de l'affichage dans le fil in-app.
      await residenceRef.collection("mail").add(newMessage.toJson());

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
