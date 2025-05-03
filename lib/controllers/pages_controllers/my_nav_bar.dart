import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'my_tab_bar_controller.dart';
import 'select_lot_component_controller.dart';
import '../../models/pages_models/lot.dart';
import '../../models/enum/set_logo_color.dart';

import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';

import 'package:connect_kasa/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/sinistres_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/event_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/annonces_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/my_docs.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/my_bottomnavbar_view.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/lot_bottom_sheet.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  final double? scrollController;

  const MyNavBar({super.key, required this.uid, this.scrollController});

  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> with TickerProviderStateMixin {
  final _databasesLotServices = DataBasesLotServices();
  final _loadPreferedData = LoadPreferedData();
  late final MyTabBarController tabController;

  Lot? _preferedLot;
  Lot _defaultLot = Lot(
    refLot: "",
    typeLot: "",
    type: "",
    idProprietaire: [],
    idLocataire: [],
    residenceId: "",
    residenceData: {},
    userLotDetails: {},
  );
  bool _isCsMember = false;

  @override
  void initState() {
    super.initState();
    tabController = MyTabBarController(length: 5, vsync: this);
    _initializeLot();
  }

  Future<void> _initializeLot() async {
    _preferedLot = await _loadPreferedData.loadPreferedLot();
    if (_preferedLot == null) {
      _defaultLot = await _databasesLotServices.getFirstLotByUserId(widget.uid);
      final color = _defaultLot.userLotDetails['colorSelected'];
      if (color != null) {
        Provider.of<ColorProvider>(context, listen: false).updateColor(color);
      }
    }
    _updateCsMemberStatus(_preferedLot ?? _defaultLot);
    setState(() {});
  }

  void _updateCsMemberStatus(Lot lot) {
    final csMembers = List<String>.from(lot.residenceData['csmembers'] ?? []);
    _isCsMember = csMembers.contains(widget.uid);
  }

  void _showLotSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => LotBottomSheet(
        uid: widget.uid,
        selectedLot: _preferedLot ?? _defaultLot,
        onRefresh: _initializeLot,
      ),
    );
  }

  void _navigateToPostForm() {
    Navigator.of(context).push(
      RouteController().createRoute(
        PostFormController(
          racineFolder: "residences",
          preferedLot: _preferedLot ?? _defaultLot,
          uid: widget.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = MediaQuery.of(context).size.height * 0.21;
    final color = context.watch<ColorProvider>().color;
    final lot = _preferedLot ?? _defaultLot;
    final residenceId = lot.residenceId;
    final residenceName = lot.residenceData['name'] ?? "";

    final List<Tab> tabs = tabController.iconTabBar.listIcons().map((iconData) {
      return Tab(icon: Icon(iconData['icon'], size: iconData['size']));
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // CONTENU PRINCIPAL
          Positioned.fill(
            top: appBarHeight,
            child: TabBarView(
              controller: tabController.tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Homeview(
                  updatePostsList: () => setState(() {}),
                  key: UniqueKey(),
                  uid: widget.uid,
                  residenceSelected: residenceId,
                  upDatescrollController: widget.scrollController,
                  colorStatut: color,
                  preferedLot: lot,
                  isCsMember: _isCsMember,
                ),
                SinistrePageView(
                  key: UniqueKey(),
                  uid: widget.uid,
                  residenceId: residenceId,
                  colorStatut: color,
                  argument1: "sinistres",
                  argument2: "incivilites",
                  argument3: "communication",
                ),
                EventPageView(
                  uid: widget.uid,
                  type: "events",
                  preferedLot: lot,
                  residenceSelected: residenceId,
                  colorStatut: color,
                ),
                AnnoncesPageView(
                  key: UniqueKey(),
                  uid: widget.uid,
                  residenceSelected: residenceId,
                  type: "annonces",
                  colorStatut: color,
                  scrollController: widget.scrollController ?? 0,
                ),
                MydocsPageView(
                  key: UniqueKey(),
                  uid: widget.uid,
                  lotSelected: lot,
                  colorStatut: color,
                  isCsMember: _isCsMember,
                ),
              ],
            ),
          ),

          // APPBAR CUSTOM EN STACK
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.only(
                    top: 0, left: 20, right: 20, bottom: 0),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOGO + PROFIL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            SetLogoColor.getLogoPath(
                                Theme.of(context).primaryColor),
                            width: MediaQuery.of(context).size.width / 2.5,
                            fit: BoxFit.fitWidth,
                          ),
                          Builder(
                            builder: (scaffoldContext) => GestureDetector(
                              onTap: () => Scaffold.of(scaffoldContext)
                                  .openEndDrawer(), // ✅ Correct
                              child: ProfilTile(widget.uid, 18, 15, 15, false),
                            ),
                          ),
                        ],
                      ),
                      // TABS
                      tabController.tabBar(tabs),

                      // SELECT LOT
                      InkWell(
                        onTap: _showLotSelector,
                        child: SelectLotComponentController(
                          uid: widget.uid,
                          lot,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // NAVBAR BOTTOM
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: MyBottomNavBarView(
                uid: widget.uid,
                residenceSelected: residenceId,
                residenceName: residenceName,
                selectedLot: lot,
              ),
            ),
          ),
        ],
      ),

      // END DRAWER
      endDrawer: ProfilePage(
        uid: widget.uid,
        refLot: lot.refLot,
        color: color,
      ),

      // BOUTON FLOTANT
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: SizedBox(
          height: 70,
          width: 70,
          child: FloatingActionButton(
            elevation: 1,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            onPressed: _navigateToPostForm,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.transparent, width: 0),
            ),
            child: Transform.rotate(
              angle: 330 * pi / 180,
              child: Icon(Icons.campaign,
                  size: 50, color: Theme.of(context).primaryColor),
            ),
          ),
        ),
      ),
    );
  }
}
