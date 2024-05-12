import 'dart:math';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/event_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/my_docs.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/lot.dart';
import '../../controllers/pages_controllers/my_tab_bar_controller.dart';
import '../widget_view/select_lot_component.dart';
import '../widget_view/lot_bottom_sheet.dart';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/vues/components/my_drawer.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/sinistres_page_view.dart';
import 'package:connect_kasa/vues/widget_view/my_bottomnavbar_view.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  final double scrollController;

  const MyNavBar(
      {super.key, required this.uid, required this.scrollController});

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar>
    with SingleTickerProviderStateMixin {
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();
  final LoadPreferedData _loadPreferedData = LoadPreferedData();
  late MyTabBarController tabController;

  double pad = 0;
  List<Lot?>? lot;
  Lot? preferedLot;
  late String uid;
  int nbrTab = 0;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    tabController = MyTabBarController(length: 5, vsync: this);
    _loadPreferedLot();
    _loadDefaultLot(widget.uid);
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
          "images/assets/logoCK250connectKasa.png",
          width: width / 2.2,
          fit: BoxFit.fitWidth,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          key: UniqueKey(),
          preferredSize: const Size.fromHeight(kToolbarHeight + kToolbarHeight),
          child: Column(
            children: [
              tabController.tabBar(tabs),
              InkWell(
                child: const SelectLotComponent(),
                onTap: () async {
                  //_handleGoogleSignIn();
                  _showLotBottomSheet(context, uid);
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabController.tabController,
        children: [
          Homeview(
              key: UniqueKey(),
              residenceSelected: preferedLot?.residenceId ?? "",
              uid: uid,
              upDatescrollController: widget.scrollController),
          SinistrePageView(
            key: UniqueKey(),
            residenceSelected: preferedLot?.residenceId ?? "",
            uid: uid,
            argument1: "sinistres",
            argument2: "incivilites",
          ),
          EventPageView(
            residenceSelected: preferedLot?.residenceId ?? "",
            uid: uid,
          ),
          SinistrePageView(
            key: UniqueKey(),
            residenceSelected: preferedLot?.residenceId ?? "",
            uid: uid,
            argument1: "Annonces",
          ),
          MydocsPageView(),
        ],
      ),
      endDrawer: MyDrawer(
        uid: uid,
      ),
      bottomNavigationBar: MyBottomNavBarView(
        residenceSelected: preferedLot?.residenceId ?? "",
        residenceName: preferedLot?.residenceData['name'] ?? "",
        uid: uid,
        selectedLot: preferedLot ??
            lot?.first ??
            Lot(
              refLot: "",
              typeLot: "",
              type: "",
              idProprietaire: '',
              residenceId: "",
              residenceData: {},
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.background,
          onPressed: () async {
            // String uid = uid;
            Navigator.of(context).push(
              RouteController().createRoute(
                PostFormController(
                  racineFolder: "residences",
                  preferedLot: preferedLot!,
                  uid: uid,
                ),
              ),
            );
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
          ),
        ),
      ),
    );
  }

  Future<void> _loadDefaultLot(uid) async {
    if (lot != null) {
      lot = (await _databasesLotServices.getLotByIdUser(uid));
      setState(() {});
    }
  }

  Future<void> _loadPreferedLot() async {
    if (preferedLot != null) {}
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
      },
    );
  }
}
