import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final String uid;

  final LoadUserController _loadUserController = LoadUserController();
  final FormatProfilPic formatProfilPic = FormatProfilPic();

  MyDrawer({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    DataBasesUserServices _dataBasesUserServices = DataBasesUserServices();
    late Future<User?> userProfil = _dataBasesUserServices.getUserById(uid);
    return Drawer(
      child: Column(children: [
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
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor,
            child: FutureBuilder<User?>(
              future: userProfil,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.hasData && snapshot.data != null) {
                    var user = snapshot.data!;
                    if (user.profilPic != null && user.profilPic != "") {
                      return formatProfilPic.ProfilePic(17, userProfil);
                    } else {
                      return formatProfilPic.getInitiales(34, userProfil, 17);
                    }
                  } else {
                    return formatProfilPic.getInitiales(17, userProfil, 3);
                  }
                }
              },
            ),
          ),
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
