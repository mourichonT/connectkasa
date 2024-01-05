import 'dart:convert';

import 'package:connect_kasa/vues/lot_tile_view.dart';
import 'package:flutter/material.dart';
import '../../models/datas/datas_lots.dart';
import '../../models/lot.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SelectLotController extends StatefulWidget {

  @override
  SelectLotControllerState createState() => SelectLotControllerState();
}

class SelectLotControllerState extends State<SelectLotController> {
  Lot? lot;
  List<Lot> lots = []; // Définissez le type approprié pour vos lots
  DatasLots datasLots = DatasLots();
  Lot? preferedLot;


  @override
  void initState() {
    super.initState();
    _loadPreferedLot();


  }

 _loadPreferedLot() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lotJson = prefs.getString('preferedLot') ?? '';
    if (lotJson.isNotEmpty) {
      Map<String, dynamic> lotMap = json.decode(lotJson);
      setState(() {
        preferedLot = Lot.fromJson(lotMap);
        print("je récupère 1 $preferedLot");
      });
    }
  }

  updateSelectedLot(Lot? value) {
    setState(() {
      print("je sélectionne ${value?.name}");
      preferedLot = value!;
      // Ajoutez d'autres actions si nécessaire
    });

    return preferedLot;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Container(
          //argin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: (preferedLot == null)
            ? Text("Sélectionner votre résidence")
            : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LotTileView(lot: preferedLot!),
                  Icon(Icons.arrow_drop_down),
                ])
            //Text("Lot sélectionné : $preferedLot"),
    ),
    );
  }
}
