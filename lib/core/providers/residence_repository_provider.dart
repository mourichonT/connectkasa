import 'package:connect_kasa/core/repositories/residence_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_residence_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final residenceRepositoryProvider = Provider<IResidenceRepository>((ref) {
  return FirestoreResidenceRepository();
});
