import 'package:konodal/core/repositories/agency_repository.dart';
import 'package:konodal/core/repositories/firestore_agency_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agencyRepositoryProvider = Provider<IAgencyRepository>((ref) {
  return FirestoreAgencyRepository();
});
