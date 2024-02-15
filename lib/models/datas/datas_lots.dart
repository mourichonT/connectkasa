import 'dart:convert';
import 'package:connect_kasa/models/datas/datas_residences.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';



class DatasLots {
 // ColorProvider colorProvider = context.watch<ColorProvider>();

  Lot CarreSalamboD03 = Lot(
      residence: DatasResidence().CarreSalambo,
      numProprietaire:"U0001" ,
      batiment: "D",
      lot: "03",
      selected: false,
      colorSelected: Colors.lightBlue,
      type: "Proprietaire Resident",
      refLot: '00001-D03',
      name: '',

  );


  Lot CarreSalamboD13 = Lot(
      residence: DatasResidence().CarreSalambo,
      numProprietaire: "UOOOO3",
      batiment: "D",
      lot: "13",
      selected: false,
      colorSelected: Colors.lightBlue,
      type: "Proprietaire Resident",
      refLot: '00001-D13',
      name: 'Appartement de Aude',
  );



  Lot Turin = Lot(
      residence: DatasResidence().Turin,
      numProprietaire: "UOOOO2",
      batiment: "1",
      lot: "24",
      selected: true,
      colorSelected: Colors.lightBlue,
      type: "Locataire",
      refLot: '00002-124',
      name: '',
  );

  Lot Touchy = Lot(
      residence: DatasResidence().Touchy ,
      numProprietaire: "UOOOO1",
      batiment: "A",
      lot: "34",
      selected: false,
      colorSelected: Colors.lightBlue,
      type: "Bailleur",
      refLot: '00003-A34',
      name: '',
  );


  List<Lot> listLot(){
    return [
      CarreSalamboD03, CarreSalamboD13, Turin, Touchy
    ];

  }
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


