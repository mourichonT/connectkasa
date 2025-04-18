import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/legal_texts/privacy_policy.dart';
import 'package:flutter/material.dart';

class PrivatePolicyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        child: Column(
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyTextStyle.lotName(
                        '1. Introduction', Colors.black87, SizeFont.h2.size),
                    MyTextStyle.postDesc(
                        PrivacyPolicy.intro, SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName('2. Données collectées', Colors.black87,
                        SizeFont.h2.size),
                    MyTextStyle.postDesc(PrivacyPolicy.dataCollected,
                        SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName('3. Utilisation des données',
                        Colors.black87, SizeFont.h2.size),
                    MyTextStyle.postDesc(PrivacyPolicy.dataUsage,
                        SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName('4. Partage et divulgation des données',
                        Colors.black87, SizeFont.h2.size),
                    MyTextStyle.postDesc(PrivacyPolicy.dataSharing,
                        SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName('5. Stockage et sécurité',
                        Colors.black87, SizeFont.h2.size),
                    MyTextStyle.postDesc(PrivacyPolicy.dataStorage,
                        SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName('6. Droits des utilisateurs',
                        Colors.black87, SizeFont.h2.size),
                    MyTextStyle.postDesc(PrivacyPolicy.userRights,
                        SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName(
                        '7. Modifications de la politique de confidentialité',
                        Colors.black87,
                        SizeFont.h2.size),
                    MyTextStyle.postDesc(PrivacyPolicy.policyChanges,
                        SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                    SizedBox(height: 20),
                    MyTextStyle.lotName(
                        '8. Contact', Colors.black87, SizeFont.h2.size),
                    MyTextStyle.postDesc(
                        PrivacyPolicy.contact, SizeFont.h3.size, Colors.black54,
                        textAlign: TextAlign.justify),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
