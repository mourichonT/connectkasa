import 'dart:convert';

import 'package:connect_kasa/vues/pages_vues/home_view.dart';
import 'package:connect_kasa/vues/components/my_bottomnavbar_view.dart';
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

  @override
  void initState() {
    super.initState();
    lots = datasLots.listLot();
    preferedLot;

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
        actions: <Widget>[
          IconButton(
            icon: MyTextStyle.IconDrawer(context, Icons.menu,EdgeInsets.only(top:pad)),
            tooltip: 'Show Snackbar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This is a snackbar')));
            },
          ),
        ],
        title:MyTextStyle.logo(context, "connectKasa",EdgeInsets.only(top:pad)
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
            color: Colors.white
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + kToolbarHeight),
          child: Column(
            children: [
              tabController.tabBar(tabs),
              InkWell(child:
              SelectLotComponent(),
              onTap:() {
                _showLotBottomSheet(context);
              })
            ],
          ),)
        ),

      body: Homeview(),


      bottomNavigationBar:MyBottomNavBarView(),

      floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container (
          height: 65,
            width: 65,
            child:FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.background,
            onPressed: () {
              clearSharedPreferences();
              print("je suis la");
            },
            child: Icon(Icons.notifications_active, size: 30, color: Theme.of(context).primaryColor,),
            shape: CircleBorder(), // Utilisez CircleBorder pour définir la forme du bouton
            materialTapTargetSize: MaterialTapTargetSize.padded)),

    );
  }

  void _showLotBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return LotBottomSheet(preferedLot);
      },
    );
  }

  void clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("SharedPreferences cleared!");
  }

}
