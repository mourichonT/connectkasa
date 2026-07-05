import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/message_provider.dart';
import 'my_tab_bar_controller.dart';
import 'select_lot_component_controller.dart';
import '../../models/pages_models/lot.dart';
import '../../models/enum/set_logo_color.dart';

import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/post_form_controller.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';

import 'package:connect_kasa/vues/pages_vues/no_lot/attach_existing_lot_page.dart';
import 'package:connect_kasa/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
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
  final _loadUserController = LoadUserController();
  late final MyTabBarController tabController;
  double _calculatedAppBarHeight = 0;
  List<Lot>? _lotsList;
  bool _hasNoLot = false;

  Lot? _preferedLot;
  Lot _defaultLot = Lot(
    refLot: "",
    id: "",
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = MediaQuery.of(context).size.height * 0.26;
      setState(() {
        _calculatedAppBarHeight = height;
      });
    });
  }

  Future<void> _initializeLot() async {
    _lotsList = await _databasesLotServices.getLotByIdUser(widget.uid);
    _preferedLot = await _loadPreferedData.loadPreferedLot();

    // Aucun lot du tout (ni préféré, ni dans la liste) : rien à afficher
    // dans les onglets habituels. getFirstLotByUserId lèverait une
    // Exception non gérée dans ce cas (item UX du backlog) ; on le détecte ici
    // directement depuis _lotsList, déjà chargé, plutôt que de s'appuyer
    // sur cette exception comme flux de contrôle.
    if (_preferedLot == null && (_lotsList?.isEmpty ?? true)) {
      if (mounted) setState(() => _hasNoLot = true);
      return;
    }

    if (_preferedLot == null) {
      _defaultLot = await _databasesLotServices.getFirstLotByUserId(widget.uid);
      final color = _defaultLot.userLotDetails['colorSelected'];
      if (color != null) {
        Provider.of<ColorProvider>(context, listen: false).updateColor(color);
      }
    }
    _updateCsMemberStatus(_preferedLot ?? _defaultLot);
    setState(() => _hasNoLot = false);

    // Lance l'écoute des messages ici, une fois résidence connue
    final residenceId = (_preferedLot ?? _defaultLot).residenceId;
    if (residenceId.isNotEmpty) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);
      messageProvider.listenForMessages(
        residenceId: residenceId,
        currentUserId: widget.uid,
      );
    }
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
        // nouveau callback:
        onLotSelected: (Lot newLot) async {
          // 1) Appliquer immédiatement le nouveau lot localement
          setState(() {
            _preferedLot = newLot;
            _updateCsMemberStatus(newLot);
          });

          // 2) Mettre à jour la couleur (si présente) — parent s'en charge
          final colorString = newLot.userLotDetails['colorSelected'];
          if (colorString != null) {
            Provider.of<ColorProvider>(context, listen: false)
                .updateColor(colorString);
          }

          // 3) (optionnel) rafraîchir la liste des lots et relancer l'écoute messages
          _lotsList = await _databasesLotServices.getLotByIdUser(widget.uid);

          final residenceId = newLot.residenceId;
          if (residenceId.isNotEmpty) {
            final messageProvider =
                Provider.of<MessageProvider>(context, listen: false);
            messageProvider.listenForMessages(
              residenceId: residenceId,
              currentUserId: widget.uid,
            );
          }
        },
        lots: _lotsList ?? [],
      ),
    );
  }

  // void _showLotSelector() {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.white,
  //     showDragHandle: true,
  //     builder: (_) => LotBottomSheet(
  //         uid: widget.uid,
  //         selectedLot: _preferedLot ?? _defaultLot,
  //         onRefresh: _initializeLot,
  //         lots: _lotsList ?? []),
  //   );
  // }

  Widget _buildNoLotScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  "images/assets/logoCKvertconnectKasa.png",
                  width: width / 1.5,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MyTextStyle.lotDesc(
                  "Vous n'êtes pour l'instant rattaché à aucun lot.",
                  SizeFont.h2.size,
                ),
              ),
              const Spacer(),
              ButtonAdd(
                text: "Rechercher ma résidence et mon lot",
                color: const Color.fromRGBO(72, 119, 91, 1.0),
                horizontal: 30,
                vertical: 10,
                size: SizeFont.h3.size,
                function: () async {
                  final attached = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AttachExistingLotPage(uid: widget.uid),
                    ),
                  );
                  if (attached == true) {
                    _initializeLot();
                  }
                },
              ),
              const SizedBox(height: 16),
              ButtonAdd(
                text: "Se déconnecter",
                color: Colors.transparent,
                colorText: const Color.fromRGBO(72, 119, 91, 1.0),
                borderColor: const Color.fromRGBO(72, 119, 91, 1.0),
                horizontal: 30,
                vertical: 10,
                size: SizeFont.h3.size,
                function: () async {
                  context.read<MessageProvider>().reset();
                  await _loadUserController.handleGoogleSignOut();
                  if (!context.mounted) return;
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                  LoadPreferedData.clearSharedPreferences();
                },
              ),
            ],
          ),
        ),
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
    if (_hasNoLot) {
      return _buildNoLotScreen(context);
    }

    //final double appBarHeight = MediaQuery.of(context).size.height * 0.26;
    // final color = context.watch<ColorProvider>().color;
    final lotColor = context.watch<ColorProvider>().color;
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
            //top: appBarHeight,
            child: TabBarView(
              controller: tabController.tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: max(0, _calculatedAppBarHeight - 15)),
                  child: Homeview(
                    updatePostsList: () => setState(() {}),
                    key: UniqueKey(),
                    uid: widget.uid,
                    residenceSelected: residenceId,
                    upDatescrollController: widget.scrollController,
                    colorStatut: lotColor,
                    preferedLot: lot,
                    isCsMember: _isCsMember,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: _calculatedAppBarHeight,
                  ),
                  child: SinistrePageView(
                    key: UniqueKey(),
                    uid: widget.uid,
                    residenceId: residenceId,
                    colorStatut: lotColor,
                    argument1: "sinistres",
                    argument2: "incivilites",
                    argument3: "communication",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: _calculatedAppBarHeight,
                  ),
                  child: EventPageView(
                    uid: widget.uid,
                    type: "events",
                    preferedLot: lot,
                    residenceSelected: residenceId,
                    colorStatut: lotColor,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: _calculatedAppBarHeight,
                  ),
                  child: AnnoncesPageView(
                    key: UniqueKey(),
                    uid: widget.uid,
                    residenceSelected: residenceId,
                    type: "annonces",
                    colorStatut: lotColor,
                    scrollController: widget.scrollController ?? 0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: _calculatedAppBarHeight,
                  ),
                  child: MydocsPageView(
                    key: UniqueKey(),
                    uid: widget.uid,
                    lotSelected: lot,
                    colorStatut: lotColor,
                    isCsMember: _isCsMember,
                  ),
                ),
              ],
            ),
          ),

          // APPBAR CUSTOM EN STACK
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOGO + PROFIL
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              SetLogoColor.getLogoPath(lotColor),
                              width: MediaQuery.of(context).size.width / 2.5,
                              fit: BoxFit.fitWidth,
                            ),
                            Builder(
                              builder: (scaffoldContext) => GestureDetector(
                                onTap: () => Scaffold.of(scaffoldContext)
                                    .openEndDrawer(),
                                child:
                                    ProfilTile(widget.uid, 22, 19, 22, false),
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
              )),

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
      endDrawer: _lotsList == null
          ? const Center(child: CircularProgressIndicator())
          : ProfilePage(
              uid: widget.uid,
              idLot: lot.id!,
              color: lotColor,
              lots: _lotsList,
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
              child: Icon(Icons.campaign, size: 50, color: lotColor),
            ),
          ),
        ),
      ),
    );
  }
}
