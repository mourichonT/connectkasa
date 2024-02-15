import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:flutter/material.dart';

class Lot {
  String _name = "";
  Residence? residence;
  String refLot; // numero (PK) dans l'application
  String? batiment; // exemple : D
  String? lot;
  MaterialColor colorSelected;
  String type; // locataire, propriétaire résidant, bailleur
  String numProprietaire;
  List<String>? numLocataire;
  bool _selected; // Champ _selected

  Lot({
    String name = "",
    required this.residence,
    required this.refLot,
    this.batiment,
    this.lot,
    required bool selected,
    required this.colorSelected,
    required this.type,
    required this.numProprietaire,
    this.numLocataire,
  })  : _selected = selected,
        _name = name,
        super();

  bool get selected => _selected;

  set selected(bool value) {
    _selected = value;
  }

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      name: json["name"] ?? "",
      residence: Residence.fromJson(json["residence"] ?? {}),
      refLot: json["refLot"] ?? "",
      batiment: json["batiment"] ?? "",
      lot: json["lot"] ?? "",
      selected: json["selected"] ?? false,
      colorSelected: MaterialColor(
        json["colorSelected"] ?? 0,
        <int, Color>{500: Color(json["colorSelected"] ?? 0)},
      ),
      type: json["type"] ?? "",
      numProprietaire: json["numProprietaire"] ?? "",
      numLocataire: json["numLocataire"] != null
          ? List<String>.from(json["numLocataire"])
          : null,
    );
  }

  toJson() {
    return {
      "name": name,
      "residence": residence?.toJson(),
      "numProprietaire": numProprietaire,
      "refLot": refLot,
      "batiment": batiment,
      "lot": lot,
      "selected": selected,
      "colorSelected": colorSelected.value,
      "type": type,
      "numUser": numProprietaire,
      "numLocataire": numLocataire,
    };
  }

  void setNumLoc(String newValue) {
    return _addNumLoc(newValue);
  }

  void _addNumLoc(String newValue) {
    numLocataire?.add(newValue);
  }

  String get name {
    return _name;
  }

  set newName(String newName) {
    if (name != newName) {
      _name = newName;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (residence != null) "residence": residence,
      if (numProprietaire != null) "numProprietaire": numProprietaire,
      if (refLot != null) "refLot": refLot,
      if (batiment != null) "batiment": batiment,
      if (lot != null) "lot": lot,
      if (selected != null) "selected": selected,
      if (colorSelected != null) "colorSelected": colorSelected,
      if (type != null) "type": type,
      if (numLocataire != null) "numLocataire": numLocataire,
    };
  }
}
