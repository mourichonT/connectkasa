/// Campagne publicitaire (collection racine "adCampaigns", gérée
/// uniquement par le backoffice - Admin SDK, hors règles Firestore). Une
/// carte pub s'intercale dans Homeview toutes les N posts, où N est un
/// réglage GLOBAL partagé par toutes les campagnes (cf. AdCampaignConfig),
/// pas un champ par-campagne. [active] n'est plus jamais écrit par le
/// backoffice : une Cloud Function planifiée (reconcile_ad_campaigns_*,
/// functions_python/main.py) l'active/désactive selon la période de
/// diffusion de la campagne et un quota de campagnes actives par
/// département - l'app ne fait que lire les campagnes actives et
/// incrémenter [impressionCount]/[clickCount] (seuls champs qu'elle a le
/// droit de modifier, cf. firestore.rules).
class AdCampaign {
  final String id;
  final String imageUrl;
  final String? targetUrl;
  final List<String> targetResidenceIds;
  final bool active;
  final int impressionCount;
  final int clickCount;

  const AdCampaign({
    required this.id,
    required this.imageUrl,
    this.targetUrl,
    required this.targetResidenceIds,
    required this.active,
    this.impressionCount = 0,
    this.clickCount = 0,
  });

  factory AdCampaign.fromMap(String id, Map<String, dynamic> map) {
    return AdCampaign(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      targetUrl: map['targetUrl'],
      targetResidenceIds: (map['targetResidenceIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
      active: map['active'] ?? false,
      impressionCount: map['impressionCount'] ?? 0,
      clickCount: map['clickCount'] ?? 0,
    );
  }
}
