import 'package:flutter/material.dart';

import '../../models/pages_models/lot.dart';
import '../../vues/widget_view/components/lot_tile_view.dart';

class SelectLotComponentController extends StatefulWidget {
  final String uid;
  final Lot defaultLot;
  const SelectLotComponentController(this.defaultLot,
      {super.key, required this.uid});

  @override
  SelectLotComponentControllerState createState() =>
      SelectLotComponentControllerState();
}

class SelectLotComponentControllerState
    extends State<SelectLotComponentController> {
  //Lot? preferedLot;
  // final LoadPreferedData _loadPreferedData = LoadPreferedData();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: LotTileView(
                toShow: false,
                lot: widget.defaultLot,
                uid: widget.uid,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
