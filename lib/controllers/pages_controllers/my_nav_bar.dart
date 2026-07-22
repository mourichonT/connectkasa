import 'dart:math';
import 'package:flutter/material.dart';
// Préfixe : package:provider (déjà utilisé dans ce fichier pour
// MessageProvider) et flutter_riverpod exportent chacun "Provider" ET
// "Consumer" - un simple hide ne suffit pas pour les deux à la fois.
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../../core/providers/notification_providers.dart';
import '../../vues/pages_vues/notifications_page.dart';
import '../providers/message_provider.dart';
import 'my_tab_bar_controller.dart';
import 'select_lot_component_controller.dart';
import '../../models/pages_models/lot.dart';
import '../../models/enum/set_logo_color.dart';

import 'package:konodal/controllers/providers/color_provider.dart';
import 'package:konodal/controllers/features/load_prefered_data.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/controllers/features/route_controller.dart';
import 'package:konodal/controllers/pages_controllers/post_form_controller.dart';

import 'package:konodal/vues/pages_vues/no_lot/no_lot_page.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/home_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/sinistres_page_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/event_page_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/annonces_page_view.dart';
import 'package:konodal/vues/pages_vues/pages_tabs/my_docs.dart';
import 'package:konodal/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:konodal/vues/widget_view/page_widget/my_bottomnavbar_view.dart';
import 'package:konodal/vues/widget_view/page_widget/lot_bottom_sheet.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:konodal/core/utils/app_logger.dart';

class MyNavBar extends StatefulWidget {
  final String uid;
  final double? scrollController;
  // Déjà résolus par LoginTransitionPage avant la navigation (cf.
  // MyApp2) : évite à _initializeLot de refaire le getLotByIdUser et la
  // résolution du lot préféré juste après avoir atterri ici. Restent
  // optionnels : MyNavBar peut aussi être atteint autrement (ex. retour
  // depuis un écran enfant qui le reconstruit), auquel cas il refait la
  // résolution normalement.
  final List<Lot>? initialLots;
  final Lot? initialPreferredLot;

  const MyNavBar({
    super.key,
    required this.uid,
    this.scrollController,
    this.initialLots,
    this.initialPreferredLot,
  });

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

  // Un lot nouvellement rattaché (inscription ou rattachement self-service)
  // reste bloqué tant qu'une personne n'a pas revérifié les documents
  // déposés (isApprovedLot, cf. addLotToUser/setUser) : on ne le propose
  // donc ni comme lot par défaut, ni dans la liste soumise au sélecteur.
  // Un lot enfant groupé (groupedWithParent=true) est fusionné avec son
  // parent (même propriétaire ET même locataire) : l'afficher séparément
  // ferait doublon, exactement ce que le rattachement parent-enfant visait
  // à éviter - masqué tant qu'il reste groupé, ré-affiché dès qu'il est
  // dégroupé (locataire potentiellement distinct, cf. project_lot_parent_child).
  Future<List<Lot>> _fetchApprovedLots() async {
    final allLots = await _databasesLotServices
        .getLotByIdUser(widget.uid)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));
    return allLots
        .where((lot) =>
            lot.userLotDetails['isApprovedLot'] == true &&
            !lot.groupedWithParent)
        .toList();
  }

  Future<void> _initializeLot() async {
    try {
      // Cède la main avant toute chose : appelée en fire-and-forget depuis
      // initState(), cette méthode doit finir son build synchronement.
      // Quand initialLots est fourni, la branche ci-dessous n'a plus aucun
      // await avant updateColor/setState (contrairement à l'ancien chemin,
      // qui attendait le fetch Firestore) - sans ce yield, ces appels
      // s'exécutaient encore pendant la phase de build de initState(),
      // provoquant "setState() or markNeedsBuild() called during build".
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      // Déjà résolus par LoginTransitionPage (cf. commentaire sur
      // widget.initialLots) : évite de refaire ici le getLotByIdUser et la
      // lecture SharedPreferences déjà faits juste avant la navigation.
      if (widget.initialLots != null) {
        _lotsList = widget.initialLots;
        _preferedLot = widget.initialPreferredLot;
      } else {
        _lotsList = await _fetchApprovedLots();

        // Le cache local (SharedPreferences) peut contenir un JSON dans un
        // ancien format (avant un renommage/regroupement de champs sur Lot/
        // Agency/Address) : Lot.fromJson() peut alors lever une exception.
        // Sans ce try/catch, cette exception remontait hors de
        // _initializeLot() (appelée en fire-and-forget depuis initState()),
        // jamais rattrapée nulle part.
        Lot? cachedPreferedLot;
        try {
          cachedPreferedLot =
              await _loadPreferedData.loadPreferedLot(widget.uid);
        } catch (e) {
          appLog("Lot préféré en cache illisible (format obsolète ?), ignoré : $e");
          cachedPreferedLot = null;
        }

        // Ne fait confiance au cache que si ce lot est toujours présent dans
        // la liste fraîchement lue depuis Firestore : un lot peut avoir été
        // révoqué, supprimé, ou repassé à isApprovedLot: false depuis la
        // dernière mise en cache - sans cette vérification, un utilisateur
        // pouvait rester bloqué sur un lot fantôme au lieu de retomber sur
        // l'écran "aucun lot". Utilise l'objet FRAIS de _lotsList (pas
        // cachedPreferedLot lui-même) : sinon idProprietaire/idLocataire
        // restaient ceux du cache, par exemple un propriétaire déjà détaché
        // continuait d'apparaître comme destinataire de messages ("Mon
        // proprio.") jusqu'à ce que le cache expire.
        _preferedLot = null;
        if (cachedPreferedLot != null) {
          for (final lot in _lotsList ?? <Lot>[]) {
            if (lot.id == cachedPreferedLot.id) {
              _preferedLot = lot;
              break;
            }
          }
        }
      }

      // Aucun lot approuvé du tout (ni préféré, ni dans la liste) : rien à
      // afficher dans les onglets habituels.
      if (_preferedLot == null && (_lotsList?.isEmpty ?? true)) {
        if (mounted) setState(() => _hasNoLot = true);
        return;
      }

      if (_preferedLot == null) {
        _defaultLot = _lotsList!.first;
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
    } catch (e) {
      // Filet de sécurité : une erreur inattendue ici ne doit jamais laisser
      // l'app figée sur le loader - on retombe sur l'écran "aucun lot"
      // plutôt que de bloquer l'accès complet à l'application.
      appLog("Erreur lors de l'initialisation du lot actif : $e");
      if (mounted) setState(() => _hasNoLot = true);
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
          _lotsList = await _fetchApprovedLots();

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
      // Filet de sécurité seulement : LoginTransitionPage résout déjà ce cas
      // avant même de monter MyNavBar. Ne peut se produire ici que si un lot
      // a été révoqué/repassé à isApprovedLot: false pendant la session.
      return NoLotPage(uid: widget.uid);
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
                            Row(
                              children: [
                                riverpod.Consumer(
                                  builder: (context, ref, child) {
                                    final notifications = ref
                                        .watch(
                                            notificationsProvider(widget.uid))
                                        .valueOrNull;
                                    final hasUnread = notifications
                                            ?.any((n) => !n.read) ??
                                        false;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.notifications_outlined,
                                              color: Colors.black54),
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => NotificationsPage(
                                                  uid: widget.uid),
                                            ),
                                          ),
                                        ),
                                        if (hasUnread)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 12,
                                                minHeight: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                Builder(
                                  builder: (scaffoldContext) => GestureDetector(
                                    onTap: () => Scaffold.of(scaffoldContext)
                                        .openEndDrawer(),
                                    child: profilTile(
                                        widget.uid, 22, 19, 22, false),
                                  ),
                                ),
                              ],
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
