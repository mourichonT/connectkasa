import 'package:connect_kasa/controllers/features/agency_search_flow.dart';
import 'package:connect_kasa/core/providers/agency_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AgencySearchFlow pour un serviceType donné ("serviceSyndic" ou
/// "geranceLocative"), injecté avec agencyRepositoryProvider.
final agencySearchFlowProvider =
    Provider.family<AgencySearchFlow, String>((ref, serviceType) {
  return AgencySearchFlow(
    serviceType: serviceType,
    repository: ref.watch(agencyRepositoryProvider),
  );
});
