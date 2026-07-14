import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:konodal/controllers/features/load_user_controller.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/providers/message_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/manage_app/management_folder_rent.dart';
import 'package:konodal/vues/pages_vues/no_lot/attach_existing_lot_page.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';

/// Page indépendante affichée par LoginTransitionPage lorsque le compte est
/// approuvé (isApproved: true) mais qu'aucun lot approuvé (isApprovedLot:
/// true) n'est encore rattaché. Auparavant cet écran était un état interne
/// de MyNavBar (_hasNoLot/_buildNoLotScreen), découvert seulement après le
/// montage de MyNavBar - ce qui provoquait un second loader visible juste
/// après celui de LoginTransitionPage. En le résolvant ici, au moment de la
/// connexion, MyNavBar peut désormais supposer qu'un lot existe toujours.
class NoLotPage extends StatelessWidget {
  final String uid;

  const NoLotPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 80, left: 24, right: 24, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "images/assets/logo_by_colors/logoVert72.119.91.png",
                        width: width / 1.5,
                      ),
                      const SizedBox(height: 150),
                      MyTextStyle.lotName(
                        "Vous n'êtes pour l'instant rattaché à aucun lot.",
                        Colors.black54,
                        SizeFont.h2.size,
                        FontWeight.normal,
                      ),
                      const SizedBox(height: 50),
                      MyTextStyle.postDesc(
                        "1. Vous êtes déjà locataire ou propriétaire d'un appartement référencé dans notre application",
                        SizeFont.h3.size,
                        Colors.black54,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ButtonAdd(
                        text: "Rechercher ma résidence et mon lot",
                        color: const Color.fromRGBO(72, 119, 91, 1.0),
                        horizontal: 30,
                        vertical: 10,
                        size: SizeFont.h3.size,
                        function: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AttachExistingLotPage(uid: uid),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 50),
                      MyTextStyle.postDesc(
                        "2. Vous souhaitez soumettre votre demande de location à un propriétaire/agence immobilière",
                        SizeFont.h3.size,
                        Colors.black54,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ButtonAdd(
                        text: "Remplir mon dossier locataire",
                        color: const Color.fromRGBO(72, 119, 91, 1.0),
                        horizontal: 30,
                        vertical: 10,
                        size: SizeFont.h3.size,
                        function: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManagementFolderRent(
                                uid: uid,
                                color: const Color.fromRGBO(72, 119, 91, 1.0),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: Colors.white,
        padding: const EdgeInsets.all(2),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonAdd(
              text: "Se déconnecter",
              color: Colors.white,
              colorText: Colors.red[800]!,
              borderColor: Colors.red[800]!,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size,
              function: () async {
                context.read<MessageProvider>().reset();
                await LoadUserController().handleGoogleSignOut();
                if (!context.mounted) return;
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
