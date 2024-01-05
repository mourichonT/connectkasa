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
    required Icon icon,
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
        icon: icon,
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
}
