import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';

abstract interface class IAdCampaignRepository {
  /// La campagne active ciblant [residenceId], s'il y en a une. Au plus une
  /// à la fois est gérée pour l'instant (pas de rotation entre plusieurs
  /// campagnes actives sur la même résidence).
  Stream<AdCampaign?> watchActiveCampaign(String residenceId);

  Future<Result<void>> recordImpression(String campaignId);

  Future<Result<void>> recordClick(String campaignId);
}
