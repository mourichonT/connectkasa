import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/pages_models/lot.dart';
import 'lot_tile_view.dart';

class SelectLotComponent extends StatefulWidget {
  @override
  SelectLotComponentState createState() => SelectLotComponentState();
}

class SelectLotComponentState extends State<SelectLotComponent> {
  Lot? preferedLot;

  @override
  void initState() {
    super.initState();
    _loadPreferedLot();
  }

  Future<void> _loadPreferedLot() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lotJson = prefs.getString('preferedLot') ?? '';
    if (lotJson.isNotEmpty) {
      Map<String, dynamic> lotMap = json.decode(lotJson);
      setState(() {
        preferedLot = Lot.fromJson(lotMap);
        print("Je récupère dans SelectLotController ${preferedLot?.name}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(

      padding: EdgeInsets.symmetric(vertical: 10),
      child: Container(
        child: (preferedLot == null)
            ? Container(
          padding: EdgeInsets.symmetric(vertical: 21),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Sélectionner votre résidence"),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        )
            : Padding(
          padding: EdgeInsets.symmetric(horizontal: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LotTileView(lot:preferedLot!),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
