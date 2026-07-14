/// Adresse partagée par Residence et Agency (évite la duplication des
/// mêmes champs dans les deux modèles).
class Address {
  // Numéro et voie fusionnés en une seule ligne (ex: "14 Rue de la Paix").
  String street;
  // Optionnel (bâtiment, étage, appartement...).
  String? complement;
  String zipCode;
  String city;
  // Norme RNVP (La Poste) : "00" si l'adresse a été sélectionnée via
  // l'autocomplétion API Adresse (donc validée), "60" si saisie/validée
  // manuellement sans sélectionner de suggestion proposée par l'API.
  String codeQualite;

  Address({
    this.street = '',
    this.complement,
    this.zipCode = '',
    this.city = '',
    this.codeQualite = '60',
  });

  factory Address.fromJson(Map<String, dynamic>? json) {
    // La présence de "codeQualite" sert de marqueur de version : absent sur
    // les documents antérieurs à ce champ, qui stockaient encore numero/
    // avenue/street séparément - sans ce repli, la migration in extremis
    // (documents non couverts par le script de migration Firestore) perdrait
    // silencieusement le numéro et l'avenue à la prochaine lecture.
    final dejaMigre = json?.containsKey('codeQualite') ?? false;
    final street = dejaMigre
        ? (json?['street'] ?? '')
        : [json?['numero'], json?['avenue'], json?['street']]
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .join(' ');
    return Address(
      street: street,
      complement: json?['complement'],
      zipCode: json?['zipCode'] ?? '',
      city: json?['city'] ?? '',
      codeQualite: json?['codeQualite'] ?? '60',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'complement': complement,
      'zipCode': zipCode,
      'city': city,
      'codeQualite': codeQualite,
    };
  }
}
