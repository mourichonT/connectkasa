import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/legal_texts/info_centre.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:flutter/material.dart';

class NoApprovalPage extends StatelessWidget {
  // Renseigné uniquement en cas de refus explicite depuis le backoffice web
  // (konodal_bo) - absent tant que le compte est simplement "pas encore
  // examiné", auquel cas on garde le message générique existant.
  final String? rejectionReason;

  const NoApprovalPage({super.key, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final hasRejectionReason = rejectionReason != null && rejectionReason!.trim().isNotEmpty;
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
              "images/assets/logo_by_colors/logoVert72.119.91.png",
              width: width / 1.5,
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: MyTextStyle.lotDesc(
                hasRejectionReason
                    ? "Votre inscription a été refusée. Motif : $rejectionReason"
                    : InfoCentre.noApprovalAccount,
                SizeFont.h2.size),
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
