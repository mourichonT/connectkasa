import 'package:konodal/models/pages_models/address.dart';

class Contact {
  String? id; // Doit être nullable pour les nouveaux contacts
  String name;
  String service;
  String phone;
  String? mail;
  // Regroupée sous 'address' côté Firestore, comme Residence/Agency (évite
  // numéro/rue/ville/code postal éparpillés) - cf. address.dart.
  Address address;
  String? web;

  Contact({
    this.id, // <-- Ajouté ici
    required this.name,
    required this.phone,
    required this.service,
    Address? address,
    this.mail,
    this.web,
  }) : address = address ?? Address();

  factory Contact.fromJson(Map<String, dynamic> json) {
    // "address" absent : ancien format à plat (num/street/city/zipcode),
    // notamment emergencyContactsFr (allow write: if false - ne peut pas
    // être migré depuis l'app, seulement lu de façon rétrocompatible ici).
    final addressJson = json['address'] as Map<String, dynamic>?;
    final address = addressJson != null
        ? Address.fromJson(addressJson)
        : Address(
            street: [json['num'], json['street']]
                .whereType<String>()
                .where((s) => s.trim().isNotEmpty)
                .join(' '),
            zipCode: json['zipcode'] ?? '',
            city: json['city'] ?? '',
          );

    return Contact(
      id: json['id'], // <-- Ajouté ici
      name: json['name'],
      service: json['service'],
      phone: json['phone'],
      mail: json['mail'],
      address: address,
      web: json['web'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // <-- Ajouté ici
      'name': name,
      'service': service,
      'phone': phone,
      'mail': mail,
      'address': address.toJson(),
      'web': web,
    };
  }
}
