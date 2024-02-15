import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/datas/datas_lots.dart';
import '../../models/pages_models/lot.dart';
import 'lot_tile_view.dart';

class LotBottomSheet extends StatefulWidget {
  final Function()? onRefresh;
  final Lot? selectedLot;

  LotBottomSheet({Key? key, this.onRefresh, this.selectedLot})
      : super(key: key);
  @override
  _LotBottomSheetState createState() => _LotBottomSheetState();
}

class _LotBottomSheetState extends State<LotBottomSheet> {
  final DatasLots datasLots = DatasLots();
  late List<Lot> lots;
  Lot? preferedLot;

  loadSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString("preferedLot");
    if (json != null) {
      preferedLot = Lot.fromJson(jsonDecode(json));
      setState(() {});
    }
  }

  int? findLotInArray(List<Lot> lots) {
    if (preferedLot != null) {
      return lots
          .indexWhere((element) => element.refLot == preferedLot!.refLot);
    } else
      return null;
  }

  @override
  void initState() {
    super.initState();
    loadSharedPrefs();
    lots = datasLots.listLot();
    preferedLot = widget.selectedLot;
    //widget.onRefresh!(); // Chargez les préférences sauvegardées
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
                //print("je test le $preferedLot");
                return RadioListTile<int>(
                  title: LotTileView(lot: lots[index]),
                  value: index,
                  groupValue: findLotInArray(lots),
                  onChanged: (preferedLot) {
                    // print(preferedLot != null
                    //     ? "Construction de l'élément $index avec le lot ${lots[preferedLot].residence?.name}"
                    //     : "Rien à charger");
                    selectLot(preferedLot, context);
                  },
                );
              },
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
  selectLot(int? selectedLotIndex, context) async {
    if (selectedLotIndex != null) {
      Lot selectedLot = lots[selectedLotIndex];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String selectedLotJson = jsonEncode(selectedLot.toJson());
      //print(selectedLotJson);
      prefs.setString('preferedLot', selectedLotJson);

      // Mettez à jour l'état pour refléter le lot sélectionné
      setState(() {
        preferedLot = selectedLot;
        // widget.lot =selectedLot;

        //print("Lot sélectionné : ${selectedLot.residence?.name}");
      });
    }
  }
}
