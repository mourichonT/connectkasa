import 'package:konodal/core/repositories/ad_campaign_repository.dart';
import 'package:konodal/core/repositories/firestore_ad_campaign_repository.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
import 'package:konodal/models/pages_models/ad_campaign_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adCampaignRepositoryProvider = Provider<IAdCampaignRepository>((ref) {
  return FirestoreAdCampaignRepository();
});

/// Campagnes pub actives pour une résidence (peut en avoir plusieurs),
/// utilisé par Homeview pour s'intercaler dans le fil en les faisant tourner
/// entre elles - la fréquence d'insertion vient de [adCampaignConfigProvider]
/// (réglage global partagé, plus un champ par campagne).
final activeAdCampaignsProvider =
    StreamProvider.family<List<AdCampaign>, String>((ref, residenceId) {
  final repository = ref.watch(adCampaignRepositoryProvider);
  return repository.watchActiveCampaigns(residenceId);
});

final adCampaignConfigProvider = StreamProvider<AdCampaignConfig>((ref) {
  final repository = ref.watch(adCampaignRepositoryProvider);
  return repository.watchConfig();
});
