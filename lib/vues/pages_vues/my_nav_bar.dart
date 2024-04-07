// ignore_for_file: library_private_types_in_public_api

import 'dart:math';

import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/vues/pages_vues/home_view.dart';
import 'package:connect_kasa/vues/widget_view/my_bottomnavbar_view.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/lot.dart';
import '../../controllers/pages_controllers/my_tab_bar_controller.dart';
import '../widget_view/select_lot_component.dart';
import '../widget_view/lot_bottom_sheet.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  MyNavBar({super.key, required this.uid});

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  final LoadPreferedData _loadPreferedData = LoadPreferedData();
  final MyTabBarController tabController = MyTabBarController();
  final LoadUserController _loadUserController = LoadUserController();
  Lot? lot;
  double pad = 0;
  Lot? preferedLot;
  String uid = "";

  @override
  void initState() {
    super.initState();
    _loadPreferedLot();
    uid = widget.uid;
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
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 20,
          title: Image.asset(
            width: width / 2.2,
            "images/assets/logoCK250connectKasa.png",
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
                      //_handleGoogleSignIn();
                      _showLotBottomSheet(context, uid);
                    })
              ],
            ),
          )),
      body: preferedLot != null
          ? Homeview(
              key: UniqueKey(),
              residenceSelected: preferedLot!.residenceId,
              uid: uid,
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
              _loadUserController.handleGoogleSignOut();
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
            child: const Text("Déconnexion"),
          )
        ]),
      ),
      bottomNavigationBar: MyBottomNavBarView(
        residenceSelected: preferedLot?.residenceId ?? "",
        residenceName: preferedLot?.residenceData['name'] ?? "",
        uid: uid,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
          height: 65,
          width: 65,
          child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.background,
              onPressed: () async {
                // String uid = uid;
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
      // uid = await _loadUserController.loadUserData();
      _showLotBottomSheet(context, uid);
    } catch (e) {
      print("Erreur lors de la connexion avec Google: $e");
    }
  }
}
