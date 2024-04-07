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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'service': service,
      'phone': phone,
      'mail': mail,
      'num': num,
      'stree': street,
      'zipcode': zipcode,
      'city': city,
      'web': web
    };
  }
}
