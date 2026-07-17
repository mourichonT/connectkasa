import 'package:konodal/core/repositories/contact_repository.dart';
import 'package:konodal/core/repositories/firestore_contact_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactRepositoryProvider = Provider<IContactRepository>((ref) {
  return FirestoreContactRepository();
});
