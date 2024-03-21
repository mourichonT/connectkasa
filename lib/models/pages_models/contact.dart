class Contact {
  String name;
  String service;
  String phone;
  String? mail;
  String? adresse;
  String? web;

  Contact({
    required this.name,
    required this.phone,
    required this.service,
    this.adresse,
    this.mail,
    this.web,
  });
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'],
      service: json['service'],
      phone: json['phone'],
      mail: json['mail'],
      adresse: json['adresse'],
      web: json['web'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'service': service,
      'phone': phone,
      'mail': mail,
      'adresse': adresse,
      'web': web
    };
  }
}
