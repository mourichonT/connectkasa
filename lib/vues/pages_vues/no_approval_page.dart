import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/legal_texts/info_centre.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:flutter/material.dart';

class NoApprovalPage extends StatelessWidget {
  NoApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: SafeArea(
            child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centrer verticalement
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            // Centrer horizontalement
            child: Image.asset(
              "images/assets/logoCKvertconnectKasa.png",
              width: width / 1.5,
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: MyTextStyle.lotDesc(
                InfoCentre.NoApprovalAccount, SizeFont.h2.size),
          ),
          Spacer(),
          ButtonAdd(
              text: "Revenir à la page de connexion",
              color: Color.fromRGBO(72, 119, 91, 1.0),
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size,
              function: () {
                Navigator.pop(context);
              })
        ],
      ),
    )));
  }
}
