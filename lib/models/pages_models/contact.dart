import 'package:connect_kasa/models/pages_models/agency.dart'; // Assurez-vous d'importer Agency si vous l'utilisez ailleurs

class Contact {
  String name;
  String service;
  String phone;
  String? mail;
  String? num;
  String? street;
  String? city;
  String? zipcode;
  String? web;
  bool isExpanded; // NOUVELLE PROPRIÉTÉ: pour gérer l'état replié/déplié

  Contact({
    required this.name,
    required this.phone,
    required this.service,
    this.num,
    this.street,
    this.city,
    this.zipcode,
    this.mail,
    this.web,
    this.isExpanded = true, // Initialise à true (déplié) par défaut
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      service: json['service'],
      phone: json['phone'],
      mail: json['mail'],
      num: json['num'],
      street: json['street'],
      city: json['city'],
      zipcode: json['zipcode'],
      web: json['web'],
      isExpanded:
          json['isExpanded'] ?? true, // Récupère la valeur ou true par défaut
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'service': service,
      'phone': phone,
      'mail': mail,
      'num': num,
      'street': street, // Correction: 'stree' -> 'street'
      'zipcode': zipcode,
      'city': city,
      'web': web,
      'isExpanded': isExpanded, // Inclure dans la conversion JSON
    };
  }
}
