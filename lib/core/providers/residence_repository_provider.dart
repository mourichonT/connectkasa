import 'package:konodal/core/repositories/residence_repository.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final residenceRepositoryProvider = Provider<IResidenceRepository>((ref) {
  return FirestoreResidenceRepository();
});
