/// Réglage global partagé par toutes les campagnes pub (singleton Firestore
/// "config/adCampaigns", géré par le backoffice) : fréquence d'affichage
/// commune, retirée du modèle par-campagne AdCampaign.
class AdCampaignConfig {
  final int displayFrequency;

  const AdCampaignConfig({required this.displayFrequency});

  factory AdCampaignConfig.fromMap(Map<String, dynamic>? map) {
    return AdCampaignConfig(displayFrequency: (map?['displayFrequency'] as int?) ?? 0);
  }
}
