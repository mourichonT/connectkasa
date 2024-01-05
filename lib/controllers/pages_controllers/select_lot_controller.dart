import 'package:connect_kasa/vues/lot_tile_view.dart';
import 'package:flutter/material.dart';

import '../../Providers/lot_selection_notif.dart';
import '../../models/datas/datas_lots.dart';
import '../../models/lot.dart';
import '../../vues/show_lot_bottom_sheet.dart';


class SelectLotController extends StatefulWidget {
  @override
  SelectLotControllerState createState() => SelectLotControllerState();
}

class SelectLotControllerState extends State<SelectLotController> {
  late LotSelectionNotifier lotSelectionNotifier;
  late Lot lot;
  List<Lot> lots = []; // Définissez le type approprié pour vos lots
  DatasLots datasLots = DatasLots();

  @override
  void initState() {
    super.initState();
    //lots = datasLots.listLot();
    lotSelectionNotifier = LotSelectionNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child : InkWell(
      child: Container(
        padding: EdgeInsets.only(top: 0, bottom: 40),
        decoration: BoxDecoration(
        color: Colors.white,
        boxShadow:[BoxShadow(color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 1,
          offset: Offset(0, 1),)],),

        height: 70,
        child: Container(
          //argin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
          child:(lotSelectionNotifier.selectedLot?.name == null)
              ?Text("Selectionner votre résidence")
              :LotTileView(lot: lotSelectionNotifier.selectedLot!)
        ),),

      onTap: () => _showLotBottomSheet(context),
    ));
  }

  void _showLotBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ShowLotBottomSheet(lotSelectionNotifier: lotSelectionNotifier);
      },
    );
  }
}
