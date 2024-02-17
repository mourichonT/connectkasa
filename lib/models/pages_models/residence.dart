import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Residence {
  String name;
  String numero;
  String voie;
  String street;
  String zipCode;
  String city;
  String refGerance;
  String refResidence;
  int nombreLot;

  Residence({
    required this.name,
    required this.numero,
    required this.voie,
    required this.street,
    required this.zipCode,
    required this.city,
    required this.refGerance,
    required this.refResidence,
    this.nombreLot = 0,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
        name: json["name"] ?? "",
        numero: json["numero"] ?? "",
        voie: json["voie"] ?? "",
        street: json["street"] ?? "",
        zipCode: json["zipCode"] ?? "",
        city: json["city"] ?? "",
        refGerance: json["refGerance"] ?? "",
        refResidence: json["refResidence"] ?? "",
        nombreLot: json["nombreLot"] ?? 0);
  }

  toJson() {
    return {
      "name": name,
      "numero": numero,
      "voie": voie,
      "street": street,
      "zipcode": zipCode,
      "city": city,
      "refGerance": refGerance,
      "refResidence": refResidence,
      "nombreLot": nombreLot
    };
  }

  factory Residence.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Residence(
        name: data?["name"],
        numero: data?["numero"],
        voie: data?["voie"],
        street: data?["street"],
        zipCode: data?["zipCode"],
        city: data?["city"],
        refGerance: data?["refGerance"],
        refResidence: data?["refResidence"],
        nombreLot: data?["nombreLot"]);
  }
  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (numero != null) "numero": numero,
      if (voie != null) "voie": voie,
      if (street != null) "street": street,
      if (zipCode != null) "zipCode": zipCode,
      if (city != null) "city": city,
      if (refGerance != null) "refGerance": refGerance,
      if (refResidence != null) "refResidence": refResidence,
      if (nombreLot != null) "nombreLot": nombreLot,
    };
  }

  factory Residence.fromMap(Map<String, dynamic> map) {
    return Residence(
      name: map['name'] ?? '',
      numero: map['numero'] ?? '',
      voie: map['voie'] ?? '',
      street: map['street'] ?? '',
      zipCode: map['zipCode'] ?? '',
      city: map['city'] ?? '',
      refGerance: map['refGerance'] ?? '',
      refResidence: map['refResidence'] ?? '',
      nombreLot: map['nombreLot'] ?? 0,
    );
  }
}
