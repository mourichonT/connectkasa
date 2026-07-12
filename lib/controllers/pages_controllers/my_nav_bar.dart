import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/message_provider.dart';
import 'my_tab_bar_controller.dart';
import 'select_lot_component_controller.dart';
import '../../models/pages_models/lot.dart';
import '../../models/enum/set_logo_color.dart';

import 'package:konodal/controllers/providers/color_provider.dart';
import 'package:konodal/controllers/features/load_prefered_data.dart';
import 'package:konodal/controllers/features/load_user_controller.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/controllers/features/route_controller.dart';
import 'package:konodal/controllers/pages_controllers/post_form_controller.dart';
import 'package:konodal/models/enum/font_setting.dart';

import 'package:konodal/vues/pages_vues/no_lot/attach_existing_lot_page.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/sinistres_page_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/event_page_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/annonces_page_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/my_docs.dart';
import 'package:konodal/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:konodal/vues/widget_view/page_widget/my_bottomnavbar_view.dart';
import 'package:konodal/vues/widget_view/page_widget/lot_bottom_sheet.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  final double? scrollController;

  const MyNavBar({super.key, required this.uid, this.scrollController});

  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> with TickerProviderStateMixin {
  final GlobalKey<HomeviewState> _homeviewKey = GlobalKey<HomeviewState>();
  final GlobalKey<SinistrePageViewState> _sinistreKey =
      GlobalKey<SinistrePageViewState>();
  final GlobalKey<EventPageViewState> _eventKey =
      GlobalKey<EventPageViewState>();
  final ILotRepository _databasesLotServices = FirestoreLotRepository();
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
    _lotsList = await _databasesLotServices
        .getLotByIdUser(widget.uid)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));
    _preferedLot = await _loadPreferedData.loadPreferedLot(widget.uid);

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
      _defaultLot = await _databasesLotServices
          .getFirstLotByUserId(widget.uid)
          .then((result) =>
              result.when(success: (v) => v, failure: (error) => throw error));
    }

    // Applique la couleur du lot actif (préféré si connu, sinon le
    // premier lot de l'utilisateur) - avant, cet appel était fait
    // uniquement dans le cas "pas de lot préféré" ci-dessus, donc la
    // couleur restait celle par défaut (#48775B) dès qu'un lot préféré
    // était résolu depuis le cache (SharedPreferences) - le cas normal
    // après une reconnexion, une fois "lot préféré" scopé par uid et
    // persistant entre les sessions.
    final activeLot = _preferedLot ?? _defaultLot;
    final color = activeLot.userLotDetails['colorSelected'];
    if (color != null && mounted) {
      Provider.of<ColorProvider>(context, listen: false).updateColor(color);
    }

    _updateCsMemberStatus(activeLot);
    setState(() => _hasNoLot = false);

    // Lance l'écoute des messages ici, une fois résidence connue
    final residenceId = (_preferedLot ?? _defaultLot).residenceId;
    if (residenceId.isNotEmpty && mounted) {
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
          _lotsList = await _databasesLotServices
        .getLotByIdUser(widget.uid)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));

          final residenceId = newLot.residenceId;
          if (residenceId.isNotEmpty && mounted) {
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
                  "images/assets/logo_by_colors/logoVert72.119.91.png",
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPostForm() async {
    await Navigator.of(context).push(
      RouteController().createRoute(
        PostFormController(
          racineFolder: "residences",
          preferedLot: _preferedLot ?? _defaultLot,
          uid: widget.uid,
        ),
      ),
    );
    // Le type du post créé (sinistre/incivilité/communication/événement)
    // n'est connu qu'à l'intérieur du formulaire : on rafraîchit les trois
    // onglets susceptibles de l'afficher plutôt que de le déterminer ici.
    _homeviewKey.currentState?.refreshPosts();
    _sinistreKey.currentState?.updatePostsList();
    _eventKey.currentState?.refreshEvents();
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
                    updatePostsList: () =>
                        _homeviewKey.currentState?.refreshPosts(),
                    key: _homeviewKey,
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
                    key: _sinistreKey,
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
                    key: _eventKey,
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
                    key: ValueKey('${residenceId}_${widget.uid}_annonces'),
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
                    key: ValueKey('${residenceId}_${lot.id}_${widget.uid}'),
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
                              width: MediaQuery.of(context).size.width / 3,
                              fit: BoxFit.fitWidth,
                            ),
                            Builder(
                              builder: (scaffoldContext) => GestureDetector(
                                onTap: () => Scaffold.of(scaffoldContext)
                                    .openEndDrawer(),
                                child:
                                    profilTile(widget.uid, 22, 19, 22, false),
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
          ? const Center(child: AppLoader())
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
