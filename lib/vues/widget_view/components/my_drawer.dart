import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final String uid;

  final LoadUserController _loadUserController = LoadUserController();
  final FormatProfilPic formatProfilPic = FormatProfilPic();

  MyDrawer({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    DataBasesUserServices dataBasesUserServices = DataBasesUserServices();
    late Future<User?> userProfil = DataBasesUserServices.getUserById(uid);
    return Drawer(
      child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 60,
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 10,
                right: 10,
              ),
              child: ProfilTile(uid, 20, 18, 20, false, Colors.black87),
            ),
            ElevatedButton(
              onPressed: () async {
                _loadUserController.handleGoogleSignOut();
                Navigator.popUntil(context, ModalRoute.withName('/'));
                LoadPreferedData.clearSharedPreferences();
              },
              child: const Text("Déconnexion"),
            )
          ]),
    );
  }
}
