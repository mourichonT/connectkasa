import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/controllers/services/authentification_service.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/vues/pages_vues/home_view.dart';
import 'package:connect_kasa/vues/components/my_bottomnavbar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/lot.dart';
import '../../controllers/features/my_tab_bar_controller.dart';
import '../components/select_lot_component.dart';
import '../components/lot_bottom_sheet.dart';
import '../../controllers/features/my_texts_styles.dart';

class MyNavBar extends StatefulWidget {
  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  final LoadPreferedData _loadPreferedData = LoadPreferedData();
  final MyTabBarController tabController = MyTabBarController();
  final LoadUserController _loadUserController = LoadUserController();
  Lot? lot;
  // User? user;
  double pad = 0;
  Lot? preferedLot;
  //AuthentificationService authService = AuthentificationService();

  // Déclaration de la variable user en dehors des méthodes.
  //UserCredential? user;

  @override
  void initState() {
    super.initState();
    _loadPreferedLot();
  }

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = tabController.iconTabBar.listIcons();
    final List<Tab> tabs = icons.asMap().entries.map((entry) {
      IconData icon = entry.value;
      return Tab(
        icon: Icon(
          icon,
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.yellow,
          elevation: 20,
          title: MyTextStyle.logo(
              context, "connectKasa", EdgeInsets.only(top: pad)),
          flexibleSpace: Container(
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
                color: Colors.white),
          ),
          bottom: PreferredSize(
            key: UniqueKey(),
            preferredSize: Size.fromHeight(kToolbarHeight + kToolbarHeight),
            child: Column(
              children: [
                tabController.tabBar(tabs),
                InkWell(
                    child: SelectLotComponent(),
                    onTap: () async {
                      _handleGoogleSignIn();
                    })
              ],
            ),
          )),
      body: preferedLot != null
          ? FutureBuilder<String>(
              future: _loadUserController.loadUserData(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                } else {
                  return Homeview(
                    key: UniqueKey(),
                    residenceSelected: preferedLot!.residenceId,
                    uid: snapshot.data!,
                  );
                }
              },
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
      endDrawer: Drawer(
        child: Column(children: [
          SizedBox(
            height: 500,
          ),
          ElevatedButton(
            onPressed: () async {
              _handleGoogleSignIn();
            },
            child: const Text("Google Auth"),
          ),
          ElevatedButton(
            onPressed: () async {
              _loadUserController.handleGoogleSignOut();
            },
            child: const Text("Déconnexion"),
          )
        ]),
      ),
      bottomNavigationBar: MyBottomNavBarView(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
          height: 65,
          width: 65,
          child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.background,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PostFormController()));
              },
              child: Icon(
                Icons.notifications_active,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
              shape: CircleBorder(),
              materialTapTargetSize: MaterialTapTargetSize.padded)),
    );
  }

  Future<void> _loadPreferedLot() async {
    preferedLot = await _loadPreferedData.loadPreferedLot(preferedLot);
    setState(() {});
  }

  void _showLotBottomSheet(BuildContext context, String uid) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return LotBottomSheet(
            selectedLot: preferedLot,
            onRefresh: () {
              _loadPreferedLot();
            },
            UID: uid,
          );
        });
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      String uid = await _loadUserController.loadUserData();
      _showLotBottomSheet(context, uid);
    } catch (e) {
      print("Erreur lors de la connexion avec Google: $e");
    }
  }
  // Future<String> _loadUserData() async {
  //   user = await authService.signUpWithGoogle();
  //   String iud = user!.user!.uid;

  //   return iud;
  // }

  // Utilisation de la variable user déclarée au niveau de la classe.

  // // Utilisation de la variable user déclarée au niveau de la classe.
  // Future<void> _handleGoogleSignOut() async {
  //   try {
  //     await authService.signOutWithGoogle();
  //     print('Utilisateur déconnecté');
  //   } catch (e) {
  //     print('Erreur lors de la déconnexion avec Google: $e');
  //   }
  // }
}
