

import 'package:flutter/material.dart';
import '../../controllers/features/my_texts_styles.dart';
import '../../models/pages_models/lot.dart';

class LotTileView extends StatefulWidget {
  final Lot lot;

  LotTileView({required this.lot});

  @override
  _LotTileViewState createState() => _LotTileViewState();
}

class _LotTileViewState extends State<LotTileView> {
 // Lot? lot;
  //Lot? preferedLot;

  @override
  void initState() {
    super.initState();
    //lot = widget.lot;
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
                      MyTextStyle.lotName(widget.lot.name.isNotEmpty ? widget.lot.name : "${widget.lot.residence?.name} ${widget.lot.batiment}${widget.lot.lot} "),
                      Container(padding: EdgeInsets.only(left: 2)),
                     ]
                  ),
                  Row(
                    children: [
                      MyTextStyle.lotDesc(widget.lot.residence?.numero??"N/A"),
                      Container(padding: EdgeInsets.only(left: 2)),
                      MyTextStyle.lotDesc(widget.lot.residence?.street??"N/A"),
                      Container(padding: EdgeInsets.only(left: 2)),
                    ],
                  ),
                  Row(
                    children: [
                      MyTextStyle.lotDesc(widget.lot.residence?.zipCode??"N/A"),
                      Container(padding: EdgeInsets.only(left: 2)),
                      MyTextStyle.lotDesc(widget.lot.residence?.city??"N/A"),
                    ],
                  ),
                ],
              ),


          ],


    );
  }

}
