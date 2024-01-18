import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/datas/datas_lots.dart';
import '../../models/pages_models/lot.dart';
import 'lot_tile_view.dart';

class LotBottomSheet extends StatefulWidget {
  final Function()? onRefresh;

  LotBottomSheet( {Key? key, this.onRefresh}) : super(key: key);
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
  //  widget.lot;
    preferedLot;
    widget.onRefresh!(); // Chargez les préférences sauvegardées
    //_loadPreferedLot();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            child: ListView.builder(
              itemCount: lots.length,
              itemBuilder: (context, index) {
                return RadioListTile<Lot>(
                title: LotTileView(lot: lots[index]),
                value: lots[index],
                groupValue: preferedLot,
                onChanged: (selectedlot) {
                  print("Construction de l'élément $index avec le lot ${lots[index].residence?.name}");
                  selectLot(selectedlot, context);
                },
              );},
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              widget.onRefresh?.call();
              Navigator.pop(context);
            });
          },
          child: Text("Selectionner"),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    );
  }

  // Méthode pour sélectionner un lot
  selectLot(Lot? selectedLot, context) async {
    if (selectedLot != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String selectedLotJson = jsonEncode(selectedLot.toJson());
      prefs.setString('preferedLot', selectedLotJson);

      // Mettez à jour l'état pour refléter le lot sélectionné
      setState(() {
        preferedLot = selectedLot;
       // widget.lot =selectedLot;

        print("Lot sélectionné : $preferedLot");
      });
    }
  }

  // Charge les préférences sauvegardées ou sélectionne le premier lot par défaut
/*  _loadPreferedLot() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lotJson = prefs.getString('preferedLot') ?? '';
    if (lotJson.isNotEmpty) {
      Map<String, dynamic> lotMap = json.decode(lotJson);
      setState(() {
        preferedLot = Lot.fromJson(lotMap);
        widget.lot = preferedLot;

        print("je récupère 1 $preferedLot");
      });
    } else {
      // Si aucune préférence n'est sauvegardée, sélectionnez le premier lot par défaut
      setState(() {
        preferedLot = lots.isNotEmpty ? lots.first : null;
        widget.lot = preferedLot;
      });
    }
  }*/
}


