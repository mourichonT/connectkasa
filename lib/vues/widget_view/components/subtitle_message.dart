import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/controllers/widgets_controllers/card_contact_controller.dart';
import 'package:konodal/vues/pages_vues/chat_page/chat_page.dart';
import 'package:konodal/vues/widget_view/page_widget/chat_page_widget/message_gerance_tile.dart';
import 'package:konodal/vues/widget_view/page_widget/chat_page_widget/message_user_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class SubtitleMessage extends ConsumerStatefulWidget {
  final String residence;
  final String uid;
  final Lot? selectedLot;

  const SubtitleMessage({
    super.key,
    required this.residence,
    required this.uid,
    this.selectedLot,
  });

  @override
  ConsumerState<SubtitleMessage> createState() => _SubtitleMessageState();
}

class _SubtitleMessageState extends ConsumerState<SubtitleMessage>
    with TickerProviderStateMixin {
  late Future<List<String>> listNumUsers;
  late Future<List<User>> _allUsersInResidence;

  late final TabController _tabController;
  int nbrTab = 0;
  bool loca = true;

  @override
  void initState() {
    super.initState();
    getNbrTab();
    listNumUsers = ref
        .read(userRepositoryProvider)
        .getNumUsersByResidence(widget.residence, widget.uid)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <String>[]));
    _fetchAllUsers();
    _allUsersInResidence = Future.value(
        []); // Initialisation avec une liste vide pour éviter les erreurs de type
    _tabController = TabController(length: nbrTab, vsync: this);
  }

  getNbrTab() {
    if (widget.selectedLot!.idProprietaire!.contains(widget.uid) &&
        widget.selectedLot!.hasAgency) {
      setState(() {
        nbrTab = 3;
        loca = false;
      });
    } else if (widget.selectedLot!.idProprietaire!.contains(widget.uid) &&
        widget.selectedLot!.idLocataire != null &&
        widget.selectedLot!.idLocataire!
            .isNotEmpty && // Ajout de cette vérification
        !widget.selectedLot!.hasAgency) {
      setState(() {
        nbrTab = 3;
        loca = true;
      });
    } else {
      setState(() {
        nbrTab = 2;
      });
    }

    return nbrTab;
  }

  Future<void> _fetchAllUsers() async {
    try {
      // Récupérer la liste des IDs d'utilisateurs
      List<String> userIds = await listNumUsers;

      // Initialiser un ensemble pour stocker les IDs d'utilisateurs uniques
      Set<String> uniqueUserIds = userIds.toSet();

      // Créer une liste de futures pour récupérer les utilisateurs. Passe
      // par userByIdProvider (cache partagé) plutôt qu'un appel direct au
      // repository : les tuiles MessageUserTile/profilTile affichées plus
      // bas pour ces mêmes uids réutilisent le même résultat au lieu de
      // le refetcher individuellement.
      List<Future<User?>> userFutures = uniqueUserIds
          .map((userId) => ref.read(userByIdProvider(userId).future))
          .toList();

      // Attendre que toutes les futures soient terminées
      List<User?> usersNullable = await Future.wait(userFutures);

      // Mettre à jour l'état avec la liste des utilisateurs récupérés
      List<User> users = usersNullable
          .where((user) =>
              user != null &&
              user.uid != widget.uid &&
              !widget.selectedLot!.idLocataire!
                  .any((id) => user.uid.contains(id)))
          .cast<User>()
          .toList();
      setState(() {
        _allUsersInResidence = Future.value(users);
      });
    } catch (error) {
      appLog("Error fetching users: $error");
    }
  }

  // Un message non lu existe-t-il avec l'un de ces contacts (même logique
  // que le badge de MessageUserTile/ChatController, réappliquée ici pour
  // savoir sur quel onglet se trouve le nouveau message).
  Future<bool> _hasUnreadFrom(List<String> otherUserIds) async {
    for (final otherId in otherUserIds) {
      final ids = [widget.uid, otherId]..sort();
      final chatId = ids.join('_');
      final doc = await FirebaseFirestore.instance
          .collection('residences')
          .doc(widget.residence)
          .collection('chats')
          .doc(chatId)
          .get();
      if (!doc.exists) continue;
      final data = doc.data()!;
      final unread = widget.uid == data['from_id']
          ? (data['from_msg_num'] ?? 0)
          : (data['to_msg_num'] ?? 0);
      if (unread > 0) return true;
    }
    return false;
  }

  Future<bool> _hasUnreadFromNeighbors() async {
    // Même exclusion que la liste affichée dans _fetchAllUsers() : le
    // locataire du lot courant a déjà son propre onglet dédié, il ne doit
    // pas aussi déclencher le badge "Mes voisins".
    final neighborIds = (await listNumUsers).where((id) =>
        id != widget.uid &&
        !(widget.selectedLot?.idLocataire ?? []).contains(id));
    return _hasUnreadFrom(neighborIds.toList());
  }

  Future<bool> _hasUnreadFromOwners() =>
      _hasUnreadFrom(widget.selectedLot?.idProprietaire ?? []);

  Future<bool> _hasUnreadFromTenants() =>
      _hasUnreadFrom(widget.selectedLot?.idLocataire ?? []);

  Widget _tabWithBadge(String text, Future<bool> hasUnreadFuture) {
    return Tab(
      child: FutureBuilder<bool>(
        future: hasUnreadFuture,
        builder: (context, snapshot) {
          final hasUnread = snapshot.data ?? false;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text),
              if (hasUnread) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar.secondary(
            controller: _tabController,
            tabs: (nbrTab == 3)
                ? <Widget>[
                    _tabWithBadge('Mes voisins', _hasUnreadFromNeighbors()),

                    //condition d'affichage par type de contact
                    if (widget.selectedLot!.idProprietaire!
                        .contains(widget.uid))
                      const Tab(text: 'Mon syndic')
                    else if (widget.selectedLot?.hasAgency ?? false)
                      const Tab(text: 'Mon agence')
                    else
                      (widget.selectedLot?.idProprietaire!.length ?? 0) > 1
                          ? _tabWithBadge(
                              'Mes proprios.', _hasUnreadFromOwners())
                          : _tabWithBadge(
                              'Mon proprio.', _hasUnreadFromOwners()),
                    loca == false
                        ? const Tab(text: 'Mon agence')
                        : widget.selectedLot?.idLocataire == null ||
                                (widget.selectedLot?.idLocataire?.length ?? 0) >
                                    1
                            ? _tabWithBadge(
                                'Mes locataires', _hasUnreadFromTenants())
                            : _tabWithBadge(
                                'Mon locataire', _hasUnreadFromTenants())
                  ]
                : <Widget>[
                    _tabWithBadge('Mes voisins', _hasUnreadFromNeighbors()),
                    //condition d'affichage par type de contact
                    if (widget.selectedLot!.idProprietaire!
                        .contains(widget.uid))
                      const Tab(text: 'Mon syndic')
                    else if (widget.selectedLot?.hasAgency ?? false)
                      const Tab(text: 'Mon agence')
                    else
                      (widget.selectedLot?.idProprietaire!.length ?? 0) > 1
                          ? _tabWithBadge(
                              'Mes proprios.', _hasUnreadFromOwners())
                          : _tabWithBadge(
                              'Mon proprio.', _hasUnreadFromOwners()),
                  ]),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              FutureBuilder(
                future: _allUsersInResidence,
                builder: (context, AsyncSnapshot<List<User>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: AppLoader(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<User> allUsers = snapshot.data!;
                    List<String> csMemberUids = List<String>.from(
                        widget.selectedLot!.residenceData["csmembers"] ?? []);
                    List<User> csMembers = allUsers
                        .where((u) => csMemberUids.contains(u.uid))
                        .toList();
                    List<User> residents = allUsers
                        .where((u) => !csMemberUids.contains(u.uid))
                        .toList();

                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, top: 10, bottom: 35),
                      child: ListView(
                        children: [
                          if (csMembers.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: MyTextStyle.lotName("Le Conseil Syndical",
                                  Colors.black54, SizeFont.h2.size),
                            ),
                            ...csMembers.map((user) => InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          residence: widget.residence,
                                          idUserFrom: widget.uid,
                                          idUserTo: user.uid,
                                        ),
                                      ),
                                    );
                                    // Rafraîchit les badges "nouveau message"
                                    // des onglets au retour du chat.
                                    if (mounted) setState(() {});
                                  },
                                  child: MessageUserTile(
                                    residenceId: widget.residence,
                                    radius: 23,
                                    idUserFrom: widget.uid,
                                    idUserTo: user.uid,
                                  ),
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                          if (residents.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: MyTextStyle.lotName("La communauté",
                                  Colors.black54, SizeFont.h2.size),
                            ),
                            ...residents.map((user) => InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          residence: widget.residence,
                                          idUserFrom: widget.uid,
                                          idUserTo: user.uid,
                                        ),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  child: MessageUserTile(
                                    residenceId: widget.residence,
                                    radius: 23,
                                    idUserFrom: widget.uid,
                                    idUserTo: user.uid,
                                  ),
                                )),
                          ],
                        ],
                      ),
                    );
                  }
                },
              ),

              // partie 2
              if (widget.selectedLot!.idProprietaire!.contains(widget.uid))
                CardContactController(
                  selectedlot: widget.selectedLot!,
                  uid: widget.uid,
                  // Syndic de la résidence (pas du lot) : residenceData est
                  // un instantané brut du document Residence, il porte donc
                  // les mêmes clés geranceRef/syndicAgency.
                  geranceRef: widget.selectedLot!.residenceData['geranceRef'] !=
                          null
                      ? GeranceRef.fromJson(
                          widget.selectedLot!.residenceData['geranceRef'])
                      : null,
                  agency: widget.selectedLot!.residenceData['syndicAgency'] !=
                          null
                      ? Agency.fromJson(
                          widget.selectedLot!.residenceData['syndicAgency'])
                      : null,
                )
              else if (widget.selectedLot?.hasAgency ?? false)
                CardContactController(
                  selectedlot: widget.selectedLot!,
                  uid: widget.uid,
                  geranceRef: widget.selectedLot!.geranceRef,
                  agency: widget.selectedLot!.syndicAgency,
                )
              else
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 15, right: 15, top: 10, bottom: 35),
                    child: ListView.separated(
                      separatorBuilder: (context, index) => const Divider(),
                      itemCount: widget.selectedLot!.idProprietaire!.length,
                      itemBuilder: (context, index) {
                        String uid = widget.selectedLot!.idProprietaire![index];
                        return InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  residence: widget.residence,
                                  idUserFrom: widget.uid,
                                  idUserTo:
                                      uid, // Utilisation du uid correspondant à cet index
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                          child: MessageGeranceTile(
                            radius: 23,
                            idUserFrom:
                                uid, // Utilisation du uid correspondant à cet index
                            idUserTo: widget.uid,
                            residenceId: widget.residence,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // partie 3
              if (nbrTab == 3 && loca == false)
                CardContactController(
                  selectedlot: widget.selectedLot!,
                  geranceRef: widget.selectedLot!.geranceRef,
                  agency: widget.selectedLot!.syndicAgency,
                  uid: widget.uid,
                )
              else if (nbrTab == 3 && loca == true)
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 10, bottom: 35),
                  child: ListView.builder(
                    itemCount: widget.selectedLot!.idLocataire!.length,
                    itemBuilder: (context, index) {
                      String locataires =
                          widget.selectedLot!.idLocataire![index];
                      return InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  residence: widget.residence,
                                  idUserFrom: widget.uid,
                                  idUserTo: locataires,
                                ),
                              ),
                            );

                            // Rafraîchit les badges "nouveau message" des
                            // onglets au retour du chat.
                            if (mounted) setState(() {});
                          },
                          child: MessageUserTile(
                              residenceId: widget.residence,
                              radius: 23,
                              idUserFrom: widget.uid,
                              idUserTo: locataires));
                    },
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }
}
