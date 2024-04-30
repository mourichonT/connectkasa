import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/controllers/widgets_controllers/card_contact_controller.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page.dart';
import 'package:connect_kasa/vues/widget_view/message_user_tile.dart';
import 'package:flutter/material.dart';

class SubtitleMessage extends StatefulWidget {
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
  State<SubtitleMessage> createState() => _SubtitleMessageState();
}

class _SubtitleMessageState extends State<SubtitleMessage>
    with TickerProviderStateMixin {
  final DataBasesUserServices _dataBasesUserServices = DataBasesUserServices();
  late Future<List<String>> listNumUsers;
  late Future<List<User>> _allUsersInResidence;

  late final TabController _tabController;
  int nbrTab = 0;
  bool loca = true;

  @override
  void initState() {
    super.initState();
    getNbrTab();
    listNumUsers = _dataBasesUserServices.getNumUsersByResidence(
        widget.residence, widget.uid);
    _fetchAllUsers();
    _allUsersInResidence = Future.value(
        []); // Initialisation avec une liste vide pour éviter les erreurs de type
    _tabController = TabController(length: nbrTab, vsync: this);
  }

  getNbrTab() {
    if (widget.selectedLot?.idProprietaire == widget.uid &&
        widget.selectedLot?.refGerance != "")
      setState(() {
        nbrTab = 3;
        loca = false;
      });
    else if (widget.selectedLot?.idProprietaire == widget.uid &&
        widget.selectedLot?.refGerance == "")
      setState(() {
        nbrTab = 3;
        loca = true;
      });
    else
      setState(() {
        nbrTab = 2;
      });

    return nbrTab;
  }

  Future<void> _fetchAllUsers() async {
    try {
      // Récupérer la liste des IDs d'utilisateurs
      List<String> userIds = await listNumUsers;

      // Initialiser un ensemble pour stocker les IDs d'utilisateurs uniques
      Set<String> uniqueUserIds = userIds.toSet();

      // Créer une liste de futures pour récupérer les utilisateurs
      List<Future<User?>> userFutures = uniqueUserIds
          .map((userId) => _dataBasesUserServices.getUserById(userId))
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
      print("Error fetching users: $error");
    }
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
                    Tab(text: 'Mes voisins'),

                    //condition d'affichage par type de contact
                    if (widget.selectedLot?.idProprietaire == widget.uid)
                      Tab(text: 'Mon syndic')
                    else if (widget.selectedLot?.refGerance != "")
                      Tab(text: 'Mon agence')
                    else
                      const Tab(
                        text: 'Mon proprio',
                      ),

                    loca == false
                        ? const Tab(text: 'Mon agence')
                        : widget.selectedLot?.idLocataire == null ||
                                (widget.selectedLot?.idLocataire?.length ?? 0) >
                                    1
                            ? const Tab(text: 'Mes locataires')
                            : const Tab(text: 'Mon locataire')
                  ]
                : <Widget>[
                    Tab(text: 'Mes voisins'),
                    //condition d'affichage par type de contact
                    if (widget.selectedLot?.idProprietaire == widget.uid)
                      Tab(text: 'Mon syndic')
                    else if (widget.selectedLot?.refGerance != "")
                      Tab(text: 'Mon agence')
                    else
                      Tab(
                        text: 'Mon proprio',
                      ),
                  ]),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              Card(
                margin: EdgeInsets.all(16),
                child: FutureBuilder(
                  future: _allUsersInResidence,
                  builder: (context, AsyncSnapshot<List<User>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      List<User> allUsers = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, top: 10, bottom: 35),
                        child: ListView.separated(
                          separatorBuilder: (context, index) => Divider(),
                          itemCount: allUsers.length,
                          itemBuilder: (context, index) {
                            User user = allUsers[index];
                            return InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                              residence: widget.residence,
                                              idUserFrom: user.uid,
                                              idUserTo: widget.uid)));
                                },
                                child:
                                    MessageUserTile(radius: 23, uid: user.uid));
                          },
                        ),
                      );
                    }
                  },
                ),
              ),

              // partie 2
              if (widget.selectedLot?.idProprietaire == widget.uid)
                CardContactController(
                  widget.selectedLot!,
                  "serviceSyndic",
                  uid: widget.uid,
                  //refGerance: widget.selectedLot!.residenceData["refGerance"],
                )
              else if (widget.selectedLot?.refGerance != "")
                CardContactController(
                  widget.selectedLot!,
                  "geranceLocative",
                  uid: widget.uid,
                  //refGerance: widget.selectedLot!.residenceData["refGerance"],
                )
              else
                Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 15, right: 15, top: 10, bottom: 35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                          residence: widget.residence,
                                          idUserFrom: widget
                                              .selectedLot!.idProprietaire,
                                          idUserTo: widget.uid)));
                            },
                            child: MessageUserTile(
                              radius: 23,
                              uid: widget.selectedLot!.idProprietaire,
                            ),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
              // partie 3
              if (nbrTab == 3 && loca == false)
                CardContactController(
                  widget.selectedLot!,
                  "geranceLocative",
                  uid: widget.uid,
                  refGerance: widget.selectedLot!.residenceData["refGerance"],
                )
              else if (nbrTab == 3 && loca == true)
                Card(
                  margin: EdgeInsets.all(16),
                  child: ListView.separated(
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: widget.selectedLot!.idLocataire!.length,
                    itemBuilder: (context, index) {
                      String locataires =
                          widget.selectedLot!.idLocataire![index];
                      return InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatPage(
                                        residence: widget.residence,
                                        idUserFrom: locataires,
                                        idUserTo: widget.uid)));
                          },
                          child: MessageUserTile(radius: 23, uid: locataires));
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
