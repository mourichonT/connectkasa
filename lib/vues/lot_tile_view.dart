

import 'package:flutter/material.dart';

import '../controllers/features/my_texts_styles.dart';
import '../models/datas/datas_lots.dart';
import '../models/lot.dart';

class LotTileView extends StatefulWidget {
  final Lot lot;

  LotTileView({required this.lot});

  @override
  _LotTileViewState createState() => _LotTileViewState();
}

class _LotTileViewState extends State<LotTileView> {
  late Lot lot;

  @override
  void initState() {
    super.initState();
    lot = widget.lot;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
          //crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.only(right: 15),
              child: Icon(Icons.home_work_outlined, size: 30),
            ),
             Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MyTextStyle.lotName(widget.lot.name.isNotEmpty ? widget.lot.name : 'N/A'),
                      Container(padding: EdgeInsets.only(left: 2)),
                      MyTextStyle.lotName(widget.lot.batiment != null && widget.lot.batiment!.isNotEmpty
                          ? widget.lot.batiment!
                          : 'N/A'),
                      MyTextStyle.lotName(widget.lot.lot != null && widget.lot.lot!.isNotEmpty ? widget.lot.lot! : 'N/A'),
                    ],
                  ),
                  Row(
                    children: [
                      MyTextStyle.lotDesc(widget.lot.numero),
                      Container(padding: EdgeInsets.only(left: 2)),
                      MyTextStyle.lotDesc(widget.lot.street),
                      Container(padding: EdgeInsets.only(left: 2)),
                    ],
                  ),
                  Row(
                    children: [
                      MyTextStyle.lotDesc(widget.lot.zipCode),
                      Container(padding: EdgeInsets.only(left: 2)),
                      MyTextStyle.lotDesc(widget.lot.city),
                    ],
                  ),
                ],
              ),

            /*Container(
              child: (lot.selected)
                  ? IconButton(
                icon: Icon(Icons.check_circle_rounded),
                onPressed: () {
                  _toggleLotSelection();
                },
              )
                  : IconButton(
                icon: Icon(Icons.radio_button_unchecked_outlined),
                onPressed: () {
                  _toggleLotSelection();
                },
              ),
            )*/
          ],


    );
  }

}
