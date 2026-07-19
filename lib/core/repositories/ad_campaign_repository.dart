import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
import 'package:konodal/models/pages_models/ad_campaign_config.dart';

abstract interface class IAdCampaignRepository {
  /// Toutes les campagnes actives ciblant [residenceId] (peut en avoir
  /// plusieurs en même temps) - Homeview les fait tourner (round-robin, sur
  /// un ordre mélangé une fois par session) au lieu de toujours afficher la
  /// même.
  Stream<List<AdCampaign>> watchActiveCampaigns(String residenceId);

  /// Réglage global partagé par toutes les campagnes (fréquence
  /// d'affichage), singleton Firestore config/adCampaigns.
  Stream<AdCampaignConfig> watchConfig();

  /// Incrémente le compteur global ET le compteur par résidence
  /// (impressionsByResidence.$residenceId) - permet au backoffice
  /// d'afficher la répartition des impressions par région - ET ajoute un
  /// document détaillé (uid, residenceId, statutResident, timestamp) dans la
  /// sous-collection adCampaigns/{id}/impressions, pour un rapport événement
  /// par événement (qui, quand, depuis quelle résidence, propriétaire ou
  /// locataire). La résidence sert de dimension géographique du rapport (pas
  /// la position de l'utilisateur, qui peut se connecter loin de son lot et
  /// fausserait le signal, ex: gérance multi-résidences depuis un seul
  /// bureau). [statutResident] : "Propriétaire"/"Locataire"/"Inconnu",
  /// dérivé du lot préféré courant (idProprietaire/idLocataire), pas d'un
  /// champ dédié.
  Future<Result<void>> recordImpression(
      String campaignId, String residenceId, String uid, String statutResident);

  Future<Result<void>> recordClick(
      String campaignId, String residenceId, String uid, String statutResident);
}
