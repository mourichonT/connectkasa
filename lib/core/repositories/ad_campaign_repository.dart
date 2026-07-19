import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';

abstract interface class IAdCampaignRepository {
  /// Toutes les campagnes actives ciblant [residenceId] (peut en avoir
  /// plusieurs en même temps) - Homeview les fait tourner (round-robin, sur
  /// un ordre mélangé une fois par session) au lieu de toujours afficher la
  /// même.
  Stream<List<AdCampaign>> watchActiveCampaigns(String residenceId);

  Future<Result<void>> recordImpression(String campaignId);

  Future<Result<void>> recordClick(String campaignId);
}
