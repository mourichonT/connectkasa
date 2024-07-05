class AgencyDept {
  String fonction;
  String id;
  String mail;
  String name;
  String surname;
  String phone;

  AgencyDept({
    required this.fonction,
    required this.id,
    required this.mail,
    required this.name,
    required this.phone,
    required this.surname,
  });

  factory AgencyDept.fromJson(Map<String, dynamic> json) {
    return AgencyDept(
      fonction: json["fonction"] ?? "",
      id: json["id"] ?? "",
      mail: json["mail"] ?? "",
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
      surname: json["surname"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "fonction": fonction,
      "id": id,
      "mail": mail,
      "name": name,
      "phone": phone,
      "surname": surname,
    };
  }
}
