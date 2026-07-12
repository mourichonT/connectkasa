/// Adresse partagée par Residence et Agency (évite la duplication des 5
/// mêmes champs dans les deux modèles).
class Address {
  String numero;
  String avenue;
  String street;
  String zipCode;
  String city;

  Address({
    this.numero = '',
    this.avenue = '',
    this.street = '',
    this.zipCode = '',
    this.city = '',
  });

  factory Address.fromJson(Map<String, dynamic>? json) {
    return Address(
      numero: json?['numero'] ?? '',
      avenue: json?['avenue'] ?? '',
      street: json?['street'] ?? '',
      zipCode: json?['zipCode'] ?? '',
      city: json?['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'avenue': avenue,
      'street': street,
      'zipCode': zipCode,
      'city': city,
    };
  }
}
