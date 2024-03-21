import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/lot.dart';
import 'lot_tile_view.dart';

class SelectLotComponent extends StatefulWidget {
  const SelectLotComponent({super.key});

  @override
  SelectLotComponentState createState() => SelectLotComponentState();
}

class SelectLotComponentState extends State<SelectLotComponent> {
  Lot? preferedLot;
  final LoadPreferedData _loadPreferedData = LoadPreferedData();

  @override
  void initState() {
    super.initState();
    _loadPreferedLot();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        child: (preferedLot == null)
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 21),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Sélectionner votre résidence"),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LotTileView(lot: preferedLot!),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _loadPreferedLot() async {
    preferedLot = await _loadPreferedData.loadPreferedLot();
    setState(() {});
  }
}
