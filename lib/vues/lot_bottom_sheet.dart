import 'dart:convert';

import 'package:connect_kasa/controllers/pages_controllers/my_app.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/datas/datas_lots.dart';
import '../models/lot.dart';
import 'lot_tile_view.dart';

class LotBottomSheet extends StatefulWidget {Lot? lot;

  LotBottomSheet(this.lot, {super.key});
  @override
  _LotBottomSheetState createState() => _LotBottomSheetState();
}

class _LotBottomSheetState extends State<LotBottomSheet> {
  final DatasLots datasLots = DatasLots();
  late List<Lot> lots;
  Lot? preferedLot;
  @override
  void initState() {
    super.initState();
    lots = datasLots.listLot();
    //widget.lot = lots.first; // Sélectionnez le premier lot par défaut.

  }
  void dispose(){
    super.dispose();
    //widget.lot = preferedLot;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: ListView.builder(
        itemCount: lots.length,
        itemBuilder: (context, index) => RadioListTile<Lot>(
          title: LotTileView(lot: lots[index]),
          value: lots[index],
          groupValue: widget.lot,
          onChanged: (Lot? preferedLot) {
            //updateSelectedLot(preferedLot);
            selectLot(preferedLot, context);
            //widget.lotSelectionNotifier.setSelectedLot(selectedLot);
            //Navigator.pop(context); // Fermer le BottomSheet après la sélection.
          },
        ),
      ),
    );
  }
  updateSelectedLot(Lot? value) {
    setState(() {
      print("je sélectionne ${value?.name}");
      widget.lot = value!;
      // Ajoutez d'autres actions si nécessaire
    });

    return widget.lot!;
  }

  selectLot(Lot? selectedLot, context) async {
    if (selectedLot != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Convertir l'objet Lot en JSON
      String selectedLotJson = jsonEncode(selectedLot.toJson());

      // Enregistrer la chaîne JSON dans les préférences
      prefs.setString('preferedLot', selectedLotJson);
      updateSelectedLot(selectedLot);
    }else {
      _loadPreferedLot();

    }

    return selectedLot;
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


/*  _selectLot(Lot? selectedLot, context) async {
    if (selectedLot != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print(prefs);
      prefs.setString('preferedLot', selectedLot.name);
      setState(() {
        print("je sélectionne ${selectedLot?.name}");
        widget.lot = selectedLot;
      });
    }
  }*/

  }
