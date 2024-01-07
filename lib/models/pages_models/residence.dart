import 'package:flutter/material.dart';

class Residence{

  String name;
  String numero;
  String voie;
  String street;
  String zipCode;
  String city;
  String refGerance;
  String refResidence;
  int nombreLot;

  Residence ({
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
        name: json["name"]??"",
        numero: json["numero"]??"",
        voie: json["voie"]??"",
        street: json["street"]??"",
        zipCode: json["zipCode"]??"",
        city: json["city"]??"",
        refGerance: json["refGerance"]??"",
        refResidence: json["refResidence"]??""

    );
  }

  toJson() {
    return {
      "name": name,
      "numero": numero,
      "voie" : voie,
      "street" : street,
      "zipcode": zipCode,
      "city" : city,
      "refGerance": refGerance,
      "refResidence": refResidence
    };
  }





}