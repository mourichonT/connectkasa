import 'package:konodal/core/repositories/mail_repository.dart';
import 'package:konodal/core/repositories/firestore_mail_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mailRepositoryProvider = Provider<IMailRepository>((ref) {
  return FirestoreMailRepository();
});
