import 'dart:convert';

import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/controllers/services/authentification_service.dart';
import 'package:connect_kasa/vues/pages_vues/home_view.dart';
import 'package:connect_kasa/vues/components/my_bottomnavbar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/datas/datas_lots.dart';
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
  final MyTabBarController tabController = MyTabBarController();
  Lot? lot;
  List<Lot> lots = [];
  DatasLots datasLots = DatasLots();
  double pad = 0;
  Lot? preferedLot;
  AuthentificationService authService = AuthentificationService();

  @override
  void initState() {
    super.initState();
    lots = datasLots.listLot();
    _loadPreferedLot();
  }

  Future<void> _loadPreferedLot([Lot? selectedLot]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lotJson = prefs.getString('preferedLot') ?? '';
    if (lotJson.isNotEmpty) {
      Map<String, dynamic> lotMap = json.decode(lotJson);
      setState(() {
        preferedLot = Lot.fromJson(lotMap);
        // print(
        //     "Je récupère dans _MyNavBarState ${preferedLot?.residence?.name}");
      });
    }
  }

  void clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final List<IconData> icons = tabController.iconTabBar.listIcons();
    final List<Tab> tabs = icons.asMap().entries.map((entry) {
      int index = entry.key;
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
          /* actions: <Widget>[
            IconButton(
              icon: MyTextStyle.IconDrawer(
                  context, Icons.menu, EdgeInsets.only(top: pad)),
              tooltip: 'Show Snackbar',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is a snackbar')));
              },
            ),
          ],*/
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
                    onTap: () {
                      _loadPreferedLot();
                      _showLotBottomSheet(context);
                    })
              ],
            ),
          )),
      body: Homeview(),
      endDrawer: Drawer(
        child: Column(children: [
          SizedBox(
            height: 500,
          ),
          ElevatedButton(
              onPressed: () async {
                UserCredential user = await authService.signInWithGoogle();
                if (user.user != null && user.user!.uid != "") {
                  // Ton traitement pour stocker l'User dans Firebase
                }
              },
              child: const Text("Google Auth"))
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
                //clearSharedPreferences();
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
              shape:
                  CircleBorder(), // Utilisez CircleBorder pour définir la forme du bouton
              materialTapTargetSize: MaterialTapTargetSize.padded)),
    );
  }

  void _showLotBottomSheet(BuildContext context) {
    _loadPreferedLot();
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          //print(preferedLot?.residence?.name);
          return LotBottomSheet(
            selectedLot: preferedLot,
            onRefresh: () {
              _loadPreferedLot(preferedLot);
            },
          );
        });
  }
}
