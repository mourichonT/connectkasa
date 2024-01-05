import 'dart:convert';

import 'package:connect_kasa/models/lot.dart';
import 'package:flutter/material.dart';

import '../../controllers/features/my_texts_styles.dart';



class DatasLots {
 // ColorProvider colorProvider = context.watch<ColorProvider>();

  Lot CarreSalambo = Lot(
      numResidence: "00001",
      name: "Carré Salambo",
      numero: "412",
      voie : "rue",
      street: "Gustave Flaubert",
      batiment: "D",
      lot: "03",
      zipCode: "34070",
      city: "Montpellier",
      selected: false,
      colorSelected: Colors.lightBlue,
      type: "Proprietaire Resident",
      numAppGerance: "G0001",
      numAppProprietaire: "P0001",
      nombreResidents: 2,
      numAppLot: '00001-D03');

  Lot Turin = Lot(
      numResidence: "00002",
      name: "Le Turin",
      numero: "509",
      voie : "rue",
      street: "Bugarel",
      batiment: "1",
      lot: "24",
      zipCode: "34070",
      city: "Montpellier",
      selected: true,
      colorSelected: Colors.lightBlue,
      type: "Locataire",
      numAppGerance: "G0001",
      numAppProprietaire: "P00324",
      nombreResidents: 2,
      numAppLot: '00002-124');

  Lot Touchy = Lot(
      numResidence: "00003",
      name: "Domaine de Touchy",
      numero: "213",
      voie : "rue",
      street: "Gustave Flaubert",
      batiment: "A",
      lot: "34",
      zipCode: "34070",
      city: "Montpellier",
      selected: false,
      colorSelected: Colors.lightBlue,
      type: "Bailleur",
      numAppGerance: "G0001",
      numAppProprietaire: "P0001",
      nombreResidents: 3,
      numAppLot: '00003-A34');

    List<Lot> listLot(){
    return [
      CarreSalambo, Turin, Touchy
    ];

  }
   /*toJson() {
     Map<String, dynamic> jsonResult =
     print("Json $jsonResult");
   // Map<String, dynamic> jsonResult = Touchy.toJson();
    //print("Json $jsonResult");
    return jsonResult;
  }*/

  List<String> toJsonList() {
    List<String> lotsJson = listLot().map((lot) => jsonEncode(lot.toJson())).toList();
    print(lotsJson);
    return lotsJson;
  }

  Map<String, dynamic> toJsonListMap() {
    return {"lots": toJsonList()};
  }



  List<bool> getSelected(){
    return listLot().map((lot) => lot.selected).toList();
  }


  void toggleLotSelectiondatalot(selectedLot) async {
    selectedLot.selected = !selectedLot.selected;
    /*for (Lot lot in listLot()) {
      lot.selected = (lot == selectedLot);

    }*/
      print("je suis ckeck");
    print("${selectedLot.name}+${selectedLot.selected}");

  }
 }


