class Agency {
  String city;
  String id;
  String name;
  String numeros;
  String street;
  String voie;
  String zipCode;

  Agency({
    required this.city,
    required this.id,
    required this.name,
    required this.numeros,
    required this.street,
    required this.voie,
    required this.zipCode,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      city: json["city"] ?? "",
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      numeros: json["numeros"] ?? "",
      street: json["street"] ?? "",
      voie: json["voie"] ?? "",
      zipCode: json["zipCode"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "city": city,
      "id": id,
      "name": name,
      "numeros": numeros,
      "street": street,
      "voie": voie,
      "zipCode": zipCode,
    };
  }
}
