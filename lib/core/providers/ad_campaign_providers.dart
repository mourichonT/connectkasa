import 'package:konodal/core/repositories/ad_campaign_repository.dart';
import 'package:konodal/core/repositories/firestore_ad_campaign_repository.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adCampaignRepositoryProvider = Provider<IAdCampaignRepository>((ref) {
  return FirestoreAdCampaignRepository();
});

/// Campagnes pub actives pour une résidence (peut en avoir plusieurs),
/// utilisé par Homeview pour s'intercaler dans le fil toutes les
/// [AdCampaign.displayFrequency] posts, en les faisant tourner entre elles.
final activeAdCampaignsProvider =
    StreamProvider.family<List<AdCampaign>, String>((ref, residenceId) {
  final repository = ref.watch(adCampaignRepositoryProvider);
  return repository.watchActiveCampaigns(residenceId);
});
