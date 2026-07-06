import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';

/// Remplace DatabasesMailServices (Phase 2 du chantier architecture).
abstract interface class IMailRepository {
  /// Flux temps réel des mails d'un fil résidence/lot donné.
  Stream<Result<QuerySnapshot>> getMail(
      String uid, Lot selectedLot, List<String> accountantMail);

  Future<Result<List<Mail>>> getMailFromUid(
      String uid, Lot selectedLot, String accountantMail);

  Future<Result<void>> sendMail({
    String? subject,
    Lot? selectedLot,
    String? residenceId,
    required String message,
    required List<String> receiverId,
  });
}
