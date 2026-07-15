import 'package:konodal/controllers/features/load_user_controller.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/providers/message_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/legal_texts/info_centre.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Affichée par LoginTransitionPage quand le compte connecté n'est pas un
/// compte 'utilisateur' (accountType) : cette app est uniquement
/// l'interface résident, les comptes 'professionnel'/'superAdmin' sont
/// destinés au futur backoffice web, pas à cette interface.
class WrongAccountTypePage extends StatelessWidget {
  const WrongAccountTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final loadUserController = LoadUserController();
    return Scaffold(
        body: SafeArea(
            child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              "images/assets/logo_by_colors/logoVert72.119.91.png",
              width: width / 1.5,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MyTextStyle.lotDesc(
                InfoCentre.wrongAccountType, SizeFont.h2.size),
          ),
          const Spacer(),
          ButtonAdd(
              text: "Revenir à la page de connexion",
              color: const Color.fromRGBO(72, 119, 91, 1.0),
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size,
              function: () async {
                context.read<MessageProvider>().reset();
                await loadUserController.handleGoogleSignOut();
                if (!context.mounted) return;
                Navigator.popUntil(context, ModalRoute.withName('/'));
              })
        ],
      ),
    )));
  }
}
