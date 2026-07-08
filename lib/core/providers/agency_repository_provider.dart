import 'package:connect_kasa/core/repositories/agency_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_agency_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agencyRepositoryProvider = Provider<IAgencyRepository>((ref) {
  return FirestoreAgencyRepository();
});
