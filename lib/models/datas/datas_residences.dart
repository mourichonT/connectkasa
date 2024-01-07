import 'dart:convert';

import 'package:connect_kasa/models/pages_models/residence.dart';

class DatasResidence{

  Residence CarreSalambo = Residence(
      name: "Carré Salambo",
      numero: "412",
      voie: "Rue",
      street: "Gustave Flaubert",
      zipCode: "34070",
      city: "Montpellier",
      refGerance: "pecoul",
      refResidence: "0001"
  );

  Residence Turin = Residence(
      name: "Le Turin",
      numero: "509",
      voie: "Rue",
      street: "Bugarel",
      zipCode: "34070",
      city: "Montpellier",
      refGerance: "pecoul",
      refResidence: "0002"
  );

  Residence Touchy = Residence(
      name: "Domaine de Touchy",
      numero: "213",
      voie: "Rue",
      street: "Gustave Flaubert",
      zipCode: "34070",
      city: "Montpellier",
      refGerance: "foncia",
      refResidence: "0003"
  );


  List<Residence> listResidence(){
    return [
      CarreSalambo, Turin,Touchy
    ];
  }

  List<String> toJsonList(){
    List<String> lotsJson = listResidence().map((lot) => jsonEncode(lot.toJson())).toList();
    print(lotsJson);
    return lotsJson;
  }

}