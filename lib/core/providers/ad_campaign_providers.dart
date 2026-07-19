import 'package:konodal/core/repositories/ad_campaign_repository.dart';
import 'package:konodal/core/repositories/firestore_ad_campaign_repository.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adCampaignRepositoryProvider = Provider<IAdCampaignRepository>((ref) {
  return FirestoreAdCampaignRepository();
});

/// Campagne pub active pour une résidence (au plus une à la fois, cf.
/// IAdCampaignRepository), utilisé par Homeview pour s'intercaler dans le
/// fil toutes les [AdCampaign.displayFrequency] posts.
final activeAdCampaignProvider =
    StreamProvider.family<AdCampaign?, String>((ref, residenceId) {
  final repository = ref.watch(adCampaignRepositoryProvider);
  return repository.watchActiveCampaign(residenceId);
});
