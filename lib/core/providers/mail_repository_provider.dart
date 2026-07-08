import 'package:connect_kasa/core/repositories/mail_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_mail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mailRepositoryProvider = Provider<IMailRepository>((ref) {
  return FirestoreMailRepository();
});
