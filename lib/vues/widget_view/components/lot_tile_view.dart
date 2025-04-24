// ignore_for_file: library_private_types_in_public_api

import 'package:connect_kasa/controllers/handlers/colors_utils.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';
import '../../../controllers/features/my_texts_styles.dart';
import '../../../models/pages_models/lot.dart';

class LotTileView extends StatefulWidget {
  final Lot lot;
  final String uid;
  final bool toShow;

  const LotTileView(
      {super.key, required this.lot, required this.uid, required this.toShow});

  @override
  _LotTileViewState createState() => _LotTileViewState();
}

class _LotTileViewState extends State<LotTileView> {
  bool isProprietaire = false;
  String showNameLotProp = "";
  String showNameLotLoc = "";
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    showNameLotProp =
        widget.lot.nameProp != "" || widget.lot.nameProp.isNotEmpty
            ? widget.lot.nameProp
            : "${widget.lot.residenceData["name"]} ${widget.lot.lot} ";
    showNameLotLoc = widget.lot.nameLoc != "" || widget.lot.nameLoc.isNotEmpty
        ? widget.lot.nameLoc
        : "${widget.lot.residenceData["name"]} ${widget.lot.lot} ";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
                      isProprietaire ? showNameLotProp : showNameLotLoc,
                      Colors.black87,
                      SizeFont.h2.size),
                  Container(padding: const EdgeInsets.only(left: 2)),
                ]),
                Row(
                  children: [
                    MyTextStyle.lotDesc(
                        widget.lot.residenceData["numero"] ?? "",
                        SizeFont.h3.size),
                    Container(padding: const EdgeInsets.only(left: 2)),
                    MyTextStyle.lotDesc(
                        widget.lot.residenceData["street"] ?? "",
                        SizeFont.h3.size),
                    Container(padding: const EdgeInsets.only(left: 2)),
                  ],
                ),
                Row(
                  children: [
                    MyTextStyle.lotDesc(
                        widget.lot.residenceData["zipCode"] ?? "",
                        SizeFont.h3.size),
                    Container(padding: const EdgeInsets.only(left: 2)),
                    MyTextStyle.lotDesc(widget.lot.residenceData["city"] ?? "",
                        SizeFont.h3.size),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (widget.toShow)
          CircleAvatar(
            backgroundColor:
                ColorUtils.fromHex(widget.lot.userLotDetails['colorSelected']),
            // Utilisation de la couleur primaire du thème
            radius: 13, // Rayon du cercle
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle, // Définir la forme comme un cercle
              ),
            ),
          ),
      ],
    );
  }
}
