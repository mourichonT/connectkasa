import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/lot.dart';
import '../components/lot_tile_view.dart';

class SelectLotComponent extends StatefulWidget {
  final String uid;
  final Lot defaultLot;
  const SelectLotComponent(
      {super.key, required this.uid, required this.defaultLot});

  @override
  SelectLotComponentState createState() => SelectLotComponentState();
}

class SelectLotComponentState extends State<SelectLotComponent> {
  Lot? preferedLot;
  final LoadPreferedData _loadPreferedData = LoadPreferedData();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();

  @override
  void initState() {
    super.initState();
    _loadPreferedLot();
    _loadDefaultLot(widget.uid, widget.defaultLot);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LotTileView(
              toShow: false,
              lot: preferedLot ?? widget.defaultLot,
              uid: widget.uid,
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      )),
    );
  }

  Future<void> _loadPreferedLot() async {
    preferedLot = await _loadPreferedData.loadPreferedLot();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDefaultLot(uid, Lot defaultLot) async {
    if (preferedLot == null) {
      defaultLot = await _databasesLotServices.getFirstLotByUserId(uid);
      if (mounted) {
        setState(() {});
      }
    }
  }
}
