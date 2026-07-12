import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/agency_dept.dart';

class Agency {
  String id;
  String name;
  // Regroupés sous 'address' côté Firestore (partagé avec Residence) ;
  // getters/setters ci-dessous pour ne pas casser les appelants existants.
  // Note : "numeros" (avec un 's') est le nom historique côté Agency,
  // contrairement à "numero" côté Residence - Address utilise "numero"
  // (singulier) comme nom canonique, "numeros" reste juste le nom exposé ici.
  Address address;
  AgencyDept? syndic;

  String get numeros => address.numero;
  set numeros(String value) => address.numero = value;
  String get avenue => address.avenue;
  set avenue(String value) => address.avenue = value;
  String get street => address.street;
  set street(String value) => address.street = value;
  String get zipCode => address.zipCode;
  set zipCode(String value) => address.zipCode = value;
  String get city => address.city;
  set city(String value) => address.city = value;

  Agency({
    required String city,
    required this.id,
    required this.name,
    required String numeros,
    required String street,
    required String avenue,
    required String zipCode,
    this.syndic,
  }) : address = Address(
          numero: numeros,
          avenue: avenue,
          street: street,
          zipCode: zipCode,
          city: city,
        );

  factory Agency.fromJson(Map<String, dynamic> json) {
    final address = Address.fromJson(json["address"]);
    return Agency(
      city: address.city,
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      numeros: address.numero,
      street: address.street,
      avenue: address.avenue,
      zipCode: address.zipCode,
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
