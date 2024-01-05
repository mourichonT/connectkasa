import 'package:connect_kasa/controllers/pages_controllers/select_lot_controller.dart';
import 'package:connect_kasa/vues/home_view.dart';
import 'package:connect_kasa/vues/my_bottomnavbar_view.dart';
import 'package:flutter/material.dart';
import '../../models/datas/datas_lots.dart';
import '../../models/lot.dart';
import '../features/my_tab_bar_controller.dart';
import '../features/my_texts_styles.dart';

class MyNavBar extends StatefulWidget {

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {

  final MyTabBarController tabController = MyTabBarController();
  late Lot lot;
  List<Lot> lots = [];
  DatasLots datasLots = DatasLots();
  double pad = 25;

  @override
  void initState() {
    super.initState();
    lots = datasLots.listLot();
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + size.height/15),
          child: Column(
            children: [
              SafeArea(
                //minimum: EdgeInsets.symmetric(horizontal: 30),
                child: tabController.tabBar(tabs)),
              SelectLotController(),
            ],
          ),
        ),
      ),
      body:SingleChildScrollView(
        child: Homeview(),

      ),


      bottomNavigationBar:MyBottomNavBarView(),

      floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container (
          height: 65,
            width: 65,
            child:FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.background,
            onPressed: () {
              print("je suis la");
            },
            child: Icon(Icons.notifications_active, size: 30, color: Theme.of(context).primaryColor,),
            shape: CircleBorder(), // Utilisez CircleBorder pour définir la forme du bouton
            materialTapTargetSize: MaterialTapTargetSize.padded)),

    );
  }
}
