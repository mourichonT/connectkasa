class Contact {
  String? id; // Doit être nullable pour les nouveaux contacts
  String name;
  String service;
  String phone;
  String? mail;
  String? num;
  String? street;
  String? city;
  String? zipcode;
  String? web;
  bool isExpanded;

  Contact({
    this.id, // <-- Ajouté ici
    required this.name,
    required this.phone,
    required this.service,
    this.num,
    this.street,
    this.city,
    this.zipcode,
    this.mail,
    this.web,
    this.isExpanded = true,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'], // <-- Ajouté ici
      name: json['name'],
      service: json['service'],
      phone: json['phone'],
      mail: json['mail'],
      num: json['num'],
      street: json['street'],
      city: json['city'],
      zipcode: json['zipcode'],
      web: json['web'],
      isExpanded: json['isExpanded'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // <-- Ajouté ici
      'name': name,
      'service': service,
      'phone': phone,
      'mail': mail,
      'num': num,
      'street': street,
      'zipcode': zipcode,
      'city': city,
      'web': web,
      'isExpanded': isExpanded,
    };
  }
}
