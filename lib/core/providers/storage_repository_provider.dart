import 'package:connect_kasa/core/repositories/storage_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_storage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return FirestoreStorageRepository();
});
