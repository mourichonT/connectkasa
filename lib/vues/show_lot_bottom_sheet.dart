import 'package:flutter/material.dart';
import '../Providers/lot_selection_notif.dart';
import '../models/datas/datas_lots.dart';
import '../models/lot.dart';
import 'lot_tile_view.dart';

class ShowLotBottomSheet extends StatefulWidget {
  final LotSelectionNotifier lotSelectionNotifier;

  ShowLotBottomSheet({required this.lotSelectionNotifier});
  @override
  _ShowLotBottomSheetState createState() => _ShowLotBottomSheetState();
}

class _ShowLotBottomSheetState extends State<ShowLotBottomSheet> {
  final DatasLots datasLots = DatasLots();
  late List<Lot> lots;
  late Lot selectedLot;

  @override
  void initState() {
    super.initState();
    lots = datasLots.listLot();
    selectedLot = lots.first; // Sélectionnez le premier lot par défaut.
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
          groupValue: selectedLot,
          onChanged: (Lot? value) {
            setState(() {
              selectedLot = value!;
              widget.lotSelectionNotifier.setSelectedLot(selectedLot);
              //Navigator.pop(context); // Fermer le BottomSheet après la sélection.
            });
          },
        ),
      ),
    );
  }

  void _showLotBottomSheet(BuildContext context) async {
    Lot? selectedLot = await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ShowLotBottomSheet(lotSelectionNotifier: widget.lotSelectionNotifier);
      },
    );

    if (selectedLot != null) {
      print("Lot sélectionné : ${selectedLot.name}");
      // Faire quelque chose avec le lot sélectionné après la fermeture du BottomSheet
    }
  }
}
