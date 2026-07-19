/// Campagne publicitaire (collection racine "adCampaigns", gérée
/// uniquement par le backoffice - Admin SDK, hors règles Firestore). Une
/// carte pub s'intercale dans Homeview toutes les [displayFrequency] posts,
/// pour chaque résidence listée dans [targetResidenceIds]. L'app ne fait que
/// lire les campagnes actives et incrémenter [impressionCount]/[clickCount]
/// (seuls champs qu'elle a le droit de modifier, cf. firestore.rules).
class AdCampaign {
  final String id;
  final String imageUrl;
  final String? targetUrl;
  final List<String> targetResidenceIds;
  final int displayFrequency;
  final bool active;
  final int impressionCount;
  final int clickCount;

  const AdCampaign({
    required this.id,
    required this.imageUrl,
    this.targetUrl,
    required this.targetResidenceIds,
    required this.displayFrequency,
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
      displayFrequency: map['displayFrequency'] ?? 0,
      active: map['active'] ?? false,
      impressionCount: map['impressionCount'] ?? 0,
      clickCount: map['clickCount'] ?? 0,
    );
  }
}
