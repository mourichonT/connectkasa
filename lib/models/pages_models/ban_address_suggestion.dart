/// Une suggestion renvoyée par l'API Adresse (Base Adresse Nationale,
/// data.gouv.fr/IGN) - service public gratuit de géocodage, sans clé API.
class BanAddressSuggestion {
  final String label;
  final String housenumber;
  final String street;
  final String postcode;
  final String city;

  BanAddressSuggestion({
    required this.label,
    required this.housenumber,
    required this.street,
    required this.postcode,
    required this.city,
  });

  factory BanAddressSuggestion.fromFeature(Map<String, dynamic> feature) {
    final properties =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    return BanAddressSuggestion(
      label: properties['label'] ?? '',
      housenumber: properties['housenumber'] ?? '',
      street: properties['street'] ?? properties['name'] ?? '',
      postcode: properties['postcode'] ?? '',
      city: properties['city'] ?? '',
    );
  }
}
