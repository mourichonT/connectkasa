import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/controllers/widgets_controllers/card_contact_controller.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page.dart';
import 'package:connect_kasa/vues/widget_view/message_user_tile.dart';
import 'package:flutter/material.dart';

class SubtitleMessage extends StatefulWidget {
  const SubtitleMessage(
      {super.key,
      required this.residence,
      required this.uid,
      this.selectedLot});

  final String residence;
  final String uid;
  final Lot? selectedLot;

  @override
  State<SubtitleMessage> createState() => _SubtitleMessageState();
}

class _SubtitleMessageState extends State<SubtitleMessage>
    with TickerProviderStateMixin {
  final DataBasesUserServices _dataBasesUserServices = DataBasesUserServices();
  late Future<List<String>> listNumUsers;
  late Future<List<User>> _allUsersInResidence;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    listNumUsers = _dataBasesUserServices.getNumUsersByResidence(
        widget.residence, widget.uid);
    _fetchAllUsers();
    _allUsersInResidence = Future.value(
        []); // Initialisation avec une liste vide pour éviter les erreurs de type
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
          .where((user) => user != null && user.uid != widget.uid)
          .cast<User>()
          .toList();
      setState(() {
        _allUsersInResidence = Future.value(users);
      });
    } catch (error) {
      print("Error fetching users: $error");
    }
  }

  late final TabController _tabController;

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
          tabs: <Widget>[
            Tab(text: 'Mes voisins'),
            widget.selectedLot?.idProprietaire == widget.uid
                ? Tab(text: 'Mon syndic')
                : Tab(text: 'Mon agence'),
          ],
        ),
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
                                  print('uidFrom : ${user.uid}');
                                  print('uidTo : ${widget.uid}');
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
              if (widget.selectedLot?.idProprietaire == widget.uid)
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Specifications tab')),
                )
              else if (widget.selectedLot?.refGerance != null)
                CardContactController(
                  widget.selectedLot,
                  "geranceLocative",
                  uid: widget.uid,
                )
              else
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Center(child: Text('mon Proprio')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
