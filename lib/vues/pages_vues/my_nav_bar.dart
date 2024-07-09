import 'dart:math';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/widgets_controllers/set_logo_color.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/annonces_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/event_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/my_docs.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page_modify.dart';
import 'package:provider/provider.dart';
import '../../models/pages_models/lot.dart';
import '../../controllers/pages_controllers/my_tab_bar_controller.dart';
import '../widget_view/select_lot_component.dart';
import '../widget_view/lot_bottom_sheet.dart';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/sinistres_page_view.dart';
import 'package:connect_kasa/vues/widget_view/my_bottomnavbar_view.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  final double? scrollController;

  const MyNavBar({super.key, required this.uid, this.scrollController});

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
    final Color colorStatut = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;
    final List<Map<String, dynamic>> icons =
        tabController.iconTabBar.listIcons();
    final List<Tab> tabs = icons.map((iconData) {
      return Tab(
        icon: Icon(
          iconData['icon'],
          size: iconData['size'],
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 20,
        title: Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Image.asset(
            SetLogoColor.getLogoPath(Theme.of(context).primaryColor),
            width: width / 2.3,
            fit: BoxFit.fitWidth,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
            color: Colors.white,
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: ProfilTile(widget.uid, 30, 14, 19, false)),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          key: UniqueKey(),
          preferredSize: const Size.fromHeight(kToolbarHeight + kToolbarHeight),
          child: Column(
            children: [
              tabController.tabBar(tabs),
              InkWell(
                child: SelectLotComponent(
                  uid: uid,
                ),
                onTap: () async {
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
            upDatescrollController: widget.scrollController,
            colorStatut: colorStatut,
          ),
          SinistrePageView(
            key: UniqueKey(),
            residenceId: preferedLot?.residenceId ?? "",
            uid: uid,
            colorStatut: colorStatut,
            argument1: "sinistres",
            argument2: "incivilites",
            argument3: "communication",
          ),
          EventPageView(
            residenceSelected: preferedLot?.residenceId ?? "",
            uid: uid,
            type: "events",
            colorStatut: colorStatut,
          ),
          AnnoncesPageView(
            key: UniqueKey(),
            residenceSelected: preferedLot?.residenceId ?? "",
            uid: uid,
            type: "annonces",
            colorStatut: colorStatut,
            scrollController: widget.scrollController ?? 00,
          ),
          MydocsPageView(
            key: UniqueKey(),
            lotSelected: preferedLot?.refLot ?? "",
            residenceSelected: preferedLot?.residenceId ?? "",
            uid: uid,
            colorStatut: colorStatut,
          ),
        ],
      ),
      endDrawer: ProfilPage(
        uid: widget.uid,
        color: colorStatut,
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
              idProprietaire: [],
              residenceId: "",
              residenceData: {},
              colorSelected: "",
            ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.background,
          onPressed: () async {
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
    preferedLot = await _loadPreferedData.loadPreferedLot(preferedLot);
    if (preferedLot != null) {
      context.read<ColorProvider>().updateColor(preferedLot!.colorSelected);
      setState(() {});
    }
  }

  void _showLotBottomSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
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
