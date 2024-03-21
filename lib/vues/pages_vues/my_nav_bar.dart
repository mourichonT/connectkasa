// ignore_for_file: library_private_types_in_public_api

import 'dart:math';

import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/vues/pages_vues/home_view.dart';
import 'package:connect_kasa/vues/components/my_bottomnavbar_view.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/lot.dart';
import '../../controllers/pages_controllers/my_tab_bar_controller.dart';
import '../components/select_lot_component.dart';
import '../components/lot_bottom_sheet.dart';

class MyNavBar extends StatefulWidget {
  const MyNavBar({super.key});

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
    final double width = MediaQuery.of(context).size.width;
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
          backgroundColor: Colors.white,
          elevation: 20,
          title: Image.asset(
            width: width / 2.5,
            "images/logoCK250connectKasa.png",
            fit: BoxFit.fitWidth,
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)),
                color: Colors.white),
          ),
          bottom: PreferredSize(
            key: UniqueKey(),
            preferredSize:
                const Size.fromHeight(kToolbarHeight + kToolbarHeight),
            child: Column(
              children: [
                tabController.tabBar(tabs),
                InkWell(
                    child: const SelectLotComponent(),
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
          const SizedBox(
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
      bottomNavigationBar: MyBottomNavBarView(
        residenceSelected: preferedLot?.residenceId ?? "",
        residenceName: preferedLot?.residenceData['name'] ?? "",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
          height: 65,
          width: 65,
          child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.background,
              onPressed: () async {
                String uid = await _loadUserController.loadUserData();
                Navigator.of(context).push(RouteController().createRoute(
                  PostFormController(
                    racineFolder: "residences",
                    preferedLot: preferedLot!,
                    uid: uid,
                  ),
                ));
              },
              shape: const CircleBorder(
                  side: BorderSide(color: Colors.black12, width: 0.3)),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              child: Transform.rotate(
                angle: 330 * pi / 180,
                child: Icon(
                  Icons.campaign,
                  size: 50,
                  color: Theme.of(context).primaryColor,
                ),
              ))),
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
            uid: uid,
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
}
