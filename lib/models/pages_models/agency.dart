import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/agency_dept.dart';

class Agency {
  String id;
  String name;
  // Regroupés sous 'address' côté Firestore (partagé avec Residence) ;
  // getters/setters ci-dessous pour ne pas casser les appelants existants.
  Address address;
  AgencyDept? syndic;

  String get street => address.street;
  set street(String value) => address.street = value;
  String get zipCode => address.zipCode;
  set zipCode(String value) => address.zipCode = value;
  String get city => address.city;
  set city(String value) => address.city = value;
  String get codeQualite => address.codeQualite;
  set codeQualite(String value) => address.codeQualite = value;

  Agency({
    required String city,
    required this.id,
    required this.name,
    required String street,
    required String zipCode,
    String codeQualite = '60',
    this.syndic,
  }) : address = Address(
          street: street,
          zipCode: zipCode,
          city: city,
          codeQualite: codeQualite,
        );

  factory Agency.fromJson(Map<String, dynamic> json) {
    final address = Address.fromJson(json["address"]);
    return Agency(
      city: address.city,
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      street: address.street,
      zipCode: address.zipCode,
      codeQualite: address.codeQualite,
      syndic: json["syndic"] != null
          ? AgencyDept.fromJson(json["syndic"] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "address": address.toJson(),
      "syndic": syndic?.toJson(),
    };
  }
}
