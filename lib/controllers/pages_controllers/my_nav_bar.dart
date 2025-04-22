import 'dart:math';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/models/enum/set_logo_color.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/old_profil_page.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/annonces_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/event_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/my_docs.dart';
import 'package:provider/provider.dart';
import '../../models/pages_models/lot.dart';
import 'my_tab_bar_controller.dart';
import 'select_lot_component_controller.dart';
import '../../vues/widget_view/page_widget/lot_bottom_sheet.dart';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/sinistres_page_view.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/my_bottomnavbar_view.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  final double? scrollController;

  const MyNavBar({super.key, required this.uid, this.scrollController});

  @override
  _MyNavBarState createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar>
    with SingleTickerProviderStateMixin {
  bool isUidLoaded = false;
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();
  final LoadPreferedData _loadPreferedData = LoadPreferedData();
  late MyTabBarController tabController;
  List<String> itemsCSMembers = [];
  late bool _isCsMember = false;

  double pad = 0;
  List<Lot?>? lot;
  Lot? preferedLot;
  late Lot defaultLot = Lot(
    nameLoc: "",
    nameProp: "",
    refLot: "",
    typeLot: "",
    type: "",
    idProprietaire: [],
    idLocataire: [],
    residenceId: "",
    residenceData: {},
    colorSelected: "",
  );
  late String uid;
  int nbrTab = 0;

  @override
  void initState() {
    super.initState();
    uid = widget.uid;
    tabController = MyTabBarController(length: 5, vsync: this);

    _loadPreferedLot().then((_) {
      if (preferedLot == null) {
        _loadDefaultLot(widget.uid);
      }
    });
  }

  void updatePostsList() {
    print("je teste la fonction de rafraichissement depuis navbar");
    setState(() {}); // Recharge l'interface, HomeView mettra à jour ses posts
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
    if (defaultLot == null) {
      return Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), // Indicateur de chargement en attendant l'initialisation
        ),
      );
    }

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
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: ProfilTile(widget.uid, 20, 15, 15, false)),
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
                child: SelectLotComponentController(
                  uid: uid,
                  defaultLot,
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
            updatePostsList: updatePostsList,
            key: UniqueKey(),
            residenceSelected:
                preferedLot?.residenceId ?? defaultLot.residenceId,
            uid: uid,
            upDatescrollController: widget.scrollController,
            colorStatut: colorStatut,
            preferedLot: preferedLot ?? defaultLot,
            isCsMember: _isCsMember,
          ),
          SinistrePageView(
            key: UniqueKey(),
            residenceId: preferedLot?.residenceId ?? defaultLot.residenceId,
            uid: uid,
            colorStatut: colorStatut,
            argument1: "sinistres",
            argument2: "incivilites",
            argument3: "communication",
          ),
          EventPageView(
            preferedLot: preferedLot ?? defaultLot,
            residenceSelected:
                preferedLot?.residenceId ?? defaultLot.residenceId,
            uid: uid,
            type: "events",
            colorStatut: colorStatut,
          ),
          AnnoncesPageView(
            key: UniqueKey(),
            residenceSelected:
                preferedLot?.residenceId ?? defaultLot.residenceId,
            uid: uid,
            type: "annonces",
            colorStatut: colorStatut,
            scrollController: widget.scrollController ?? 00,
          ),
          MydocsPageView(
            key: UniqueKey(),
            lotSelected: preferedLot ?? defaultLot,
            uid: uid,
            colorStatut: colorStatut,
            isCsMember: _isCsMember,
          ),
        ],
      ),
      endDrawer: ProfilePage(
        refLot: preferedLot?.refLot ?? defaultLot.refLot,
        uid: widget.uid,
        color: colorStatut,
      ),
      bottomNavigationBar: MyBottomNavBarView(
          residenceSelected: preferedLot?.residenceId ?? defaultLot.residenceId,
          residenceName: preferedLot?.residenceData['name'] ??
              defaultLot.residenceData['name'] ??
              "",
          uid: uid,
          selectedLot: preferedLot ?? defaultLot),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.surface,
          onPressed: () async {
            Navigator.of(context).push(
              RouteController().createRoute(
                PostFormController(
                  racineFolder: "residences",
                  preferedLot: preferedLot ?? defaultLot,
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
    if (preferedLot == null) {
      defaultLot = (await _databasesLotServices.getFirstLotByUserId(uid));
      updateCsMemberStatus(defaultLot);
      context.read<ColorProvider>().updateColor(defaultLot.colorSelected);
      setState(() {});
    }
  }

  Future<void> _loadPreferedLot() async {
    preferedLot = await _loadPreferedData.loadPreferedLot(preferedLot);
    if (preferedLot != null) {
      context.read<ColorProvider>().updateColor(preferedLot!.colorSelected);
      updateCsMemberStatus(preferedLot!);
      setState(() {});
    }
  }

  void updateCsMemberStatus(Lot lotSelected) {
    itemsCSMembers = [];
    if (lotSelected.residenceData.containsKey('csmembers') &&
        lotSelected.residenceData['csmembers'] != null) {
      itemsCSMembers =
          List<String>.from(lotSelected.residenceData['csmembers']);
    }

    setState(() {
      _isCsMember = itemsCSMembers.contains(widget.uid);
    });
  }

  void _showLotBottomSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      showDragHandle: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return LotBottomSheet(
          selectedLot: preferedLot ?? defaultLot,
          onRefresh: () {
            _loadPreferedLot();
          },
          uid: uid,
        );
      },
    );
  }
}
