// ignore_for_file: library_private_types_in_public_api

import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';
import '../../controllers/features/my_texts_styles.dart';
import '../../models/pages_models/lot.dart';

class LotTileView extends StatefulWidget {
  final Lot lot;

  const LotTileView({super.key, required this.lot});

  @override
  _LotTileViewState createState() => _LotTileViewState();
}

class _LotTileViewState extends State<LotTileView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      //crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(right: 15),
          child: const Icon(Icons.home_work_outlined, size: 30),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              MyTextStyle.lotName(
                  widget.lot.name.isNotEmpty
                      ? widget.lot.name
                      : "${widget.lot.residenceData["name"]} ${widget.lot.batiment}${widget.lot.lot} ",
                  Colors.black87,
                  SizeFont.h2.size),
              Container(padding: const EdgeInsets.only(left: 2)),
            ]),
            Row(
              children: [
                MyTextStyle.lotDesc(
                    widget.lot.residenceData["numero"] ?? "N/A", 14),
                Container(padding: const EdgeInsets.only(left: 2)),
                MyTextStyle.lotDesc(
                    widget.lot.residenceData["street"] ?? "N/A", 14),
                Container(padding: const EdgeInsets.only(left: 2)),
              ],
            ),
            Row(
              children: [
                MyTextStyle.lotDesc(
                    widget.lot.residenceData["zipCode"] ?? "N/A", 14),
                Container(padding: const EdgeInsets.only(left: 2)),
                MyTextStyle.lotDesc(
                    widget.lot.residenceData["city"] ?? "N/A", 14),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
