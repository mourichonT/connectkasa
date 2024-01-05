import 'package:connect_kasa/models/residence.dart';
import 'package:flutter/material.dart';

class Lot extends Residence {
  String numAppLot; // numero (PK) dans l'application
  String? batiment; // exemple : D
  String? lot;
  MaterialColor colorSelected;
  String type; // locataire, propriétaire résidant, bailleur
  String numAppProprietaire;

  bool _selected;  // Champ _selected

  Lot({
    required this.numAppLot,
    required String name,
    required String numero,
    required String voie,
    required String street,
    this.batiment,
    this.lot,
    required String zipCode,
    required String city,
    required bool selected,
    required this.colorSelected,
    required this.type,
    required String numAppGerance,
    required String this.numAppProprietaire,
    required String numResidence,
    required int nombreResidents,
  }) : _selected = selected, // Initialisation ici
        super(
        name: name,
        numero: numero,
        voie: voie,
        street: street,
        zipCode: zipCode,
        city: city,
        numAppGerance: numAppGerance,
        numResidence: numResidence,
        nombreResidents: nombreResidents,
      );

  bool get selected => _selected;

  set selected(bool value) {
    _selected = value;
  }


  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
        numAppLot: json["numAppLot"],
        name: json["name"],
        numero: json["numero"],
        voie: json["voie"],
        street: json["street"],
        zipCode: json["zipCode"],
        city: json["city"],
        selected: json["selected"],
        colorSelected:  MaterialColor(json["colorSelected"],
          <int, Color>{500: Color(json["colorSelected"])},),
        type: json["type"],
        numAppGerance: json["numAppGerance"],
        numAppProprietaire: json["numAppProprietaire"],
        numResidence: json["numResidence"],
        nombreResidents: json["nombreResidents"]
    );
  }

  toJson() {
    return {
      "numAppLot": numAppLot,
      "name": name,
      "numero": numero,
      "voie": voie,
      "street": street,
      "zipCode": zipCode,
      "city": city,
      "selected": selected,
      "colorSelected": colorSelected.value,
      "type": type,
      "numAppGerance":numAppGerance,
      "numAppProprietaire":numAppProprietaire,
      "numResidence": numResidence,
      "nombreResidents": nombreResidents
    };
  }
}



