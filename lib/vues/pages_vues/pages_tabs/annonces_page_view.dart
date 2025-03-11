import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/pages_controllers/filter_allannounced_controller..dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/transaction_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/add_annonceform.dart';
import 'package:connect_kasa/vues/components/annonce_tile.dart';
import 'package:connect_kasa/vues/pages_vues/sinistre_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnnoncesPageView extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final String? type;
  final Color colorStatut;
  final double scrollController;

  const AnnoncesPageView({
    super.key,
    required this.residenceSelected,
    required this.uid,
    this.type,
    required this.colorStatut,
    required this.scrollController,
  });

  @override
  State<StatefulWidget> createState() => AnnoncesPageViewState();
}

class AnnoncesPageViewState extends State<AnnoncesPageView>
    with SingleTickerProviderStateMixin {
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  final TransactionServices _transacServices = TransactionServices();
  late final TabController _tabController;
  late Future<List<Post>> _allPostsFuture;
  late Future<List<TransactionModel>> _allTransaction;
  bool _showFilters = false;
  bool _selectedTab = false;
  bool colorSelection = false;
  Color colorSelected = Colors.white;
  bool visibility = false;
  final int _priceMin = 0;
  final int _priceMax = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allPostsFuture =
        _databaseServices.getAllAnnonces(widget.residenceSelected);
    _allTransaction = _transacServices.getTransactionByUid(
        widget.uid, widget.residenceSelected);
    _tabController.addListener(_handleTabChange);

    _selectedTab = _tabController.index == 0;
  }

  void refreshTransactions() {
    setState(() {
      _allTransaction = _transacServices.getTransactionByUid(
          widget.uid, widget.residenceSelected);
    });
  }

  void _handleTabChange() {
    setState(() {
      _selectedTab = _tabController.index ==
          0; // Met à jour _showFilters en fonction de l'onglet actuellement sélectionné
    });
  }

  void updatePostsList() {
    setState(() {
      _allPostsFuture =
          _databaseServices.getAllAnnonces(widget.residenceSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 3,
      child: Column(children: <Widget>[
        TabBar.secondary(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              text: 'Tous',
            ),
            Tab(text: 'Gérer'),
            //Tab(text: 'Transactions'),
          ],
        ),
        if (_showFilters && _selectedTab)
          FilterAllAnnouncedController(
            residenceSelected: widget.residenceSelected,
            uid: widget.uid,
            onFilterUpdate: (
                {required List<String?> categorie,
                required String dateFrom,
                required String dateTo,
                required int priceMin,
                required int priceMax}) {
              setState(() {
                _allPostsFuture = _databaseServices.getAllAnnoncesWithFilters(
                    doc: widget.residenceSelected,
                    subtype: categorie,
                    dateFrom: dateFrom,
                    dateTo: dateTo,
                    priceMin: priceMin,
                    priceMax: priceMax);
              });
            },
          ),
        if (_selectedTab)
          GestureDetector(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              }); // Appel de la fonction de participation si elle est définie
            },
            child: Container(
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    MyTextStyle.lotName(
                        "Ajouter des filtres", Colors.white, SizeFont.h3.size)
                  ],
                )),
          ),
        Expanded(
          child: FutureBuilder<List<Post>>(
              future: _allPostsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Affichez un indicateur de chargement si les données ne sont pas encore disponibles
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  // Gérez les erreurs ici
                  return Text('Error: ${snapshot.error}');
                } else {
                  // Les données sont prêtes, vous pouvez maintenant utiliser snapshot.data
                  List<Post> allPosts = snapshot.data!;
                  return TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        GridView.builder(
                          itemCount: allPosts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2 / 3,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            // Assurez-vous que l'index est valide avant d'accéder à la liste
                            if (index < allPosts.length) {
                              Post post = allPosts[index];
                              // Vérifiez votre condition ici
                              if (post.type == widget.type) {
                                return Container(
                                  child: AnnonceTile(
                                      post,
                                      widget.residenceSelected,
                                      widget.uid,
                                      false,
                                      widget.colorStatut,
                                      widget.scrollController),
                                );
                              } else {
                                // Retourner un widget vide ou autre chose si la condition n'est pas remplie
                                return Container(); // ou tout autre widget approprié
                              }
                            } else {
                              // Gérez le cas où l'index est en dehors de la plage valide
                              return Container(); // ou tout autre widget approprié
                            }
                          },
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 20),
                              child: ButtonAdd(
                                  function: () {
                                    Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                AddAnnonceForm(
                                                  residence:
                                                      widget.residenceSelected,
                                                  uid: widget.uid,
                                                )));
                                  },
                                  color: color,
                                  icon: Icons.add,
                                  text: 'Ajouter une annonce',
                                  horizontal: 10,
                                  vertical: 10,
                                  size: SizeFont.h3.size),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: allPosts.length,
                              itemBuilder: (context, index) {
                                _allPostsFuture = _databaseServices
                                    .getAllAnnonces(widget.residenceSelected);
                                Post post = allPosts[index];
                                return Column(
                                  children: [
                                    if (post.user == widget.uid)
                                      SinistreTile(
                                          post,
                                          widget.residenceSelected,
                                          widget.uid,
                                          true,
                                          widget.colorStatut,
                                          updatePostsList),
                                  ],
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(height: 0),
                            ),
                          ],
                        ),
                        // Column(
                        //   children: [
                        //     Padding(
                        //       padding: const EdgeInsets.symmetric(vertical: 10),
                        //       child: Row(
                        //         crossAxisAlignment: CrossAxisAlignment.center,
                        //         mainAxisAlignment: MainAxisAlignment.center,
                        //         children: [
                        //           GestureDetector(
                        //             onTap: () {
                        //               setState(() {
                        //                 colorSelection = !colorSelection;
                        //                 visibility = !visibility;
                        //                 print(visibility);
                        //               });
                        //             },
                        //             child: Container(
                        //               width: width / 3,
                        //               height: 35,
                        //               color: colorSelection
                        //                   ? Colors.white
                        //                   : Theme.of(context).primaryColor,
                        //               child: Center(
                        //                 child: MyTextStyle.lotName(
                        //                     "En cours",
                        //                     colorSelection
                        //                         ? Theme.of(context).primaryColor
                        //                         : Colors.white,
                        //                     SizeFont.h3.size),
                        //               ),
                        //             ),
                        //           ),
                        //           GestureDetector(
                        //             onTap: () {
                        //               setState(() {
                        //                 colorSelection = !colorSelection;
                        //                 visibility = !visibility;
                        //               });
                        //             },
                        //             child: Container(
                        //               width: width / 3,
                        //               height: 35,
                        //               color: colorSelection
                        //                   ? Theme.of(context).primaryColor
                        //                   : Colors.white,
                        //               child: Center(
                        //                 child: MyTextStyle.lotName(
                        //                     "Historique",
                        //                     colorSelection
                        //                         ? Colors.white
                        //                         : Theme.of(context)
                        //                             .primaryColor,
                        //                     SizeFont.h3.size),
                        //               ),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //     FutureBuilder<List<TransactionModel>>(
                        //       future: _allTransaction,
                        //       builder: (context, snapshot) {
                        //         if (snapshot.connectionState ==
                        //             ConnectionState.waiting) {
                        //           // Affichez un indicateur de chargement si les données ne sont pas encore disponibles
                        //           return const Center(
                        //             child: CircularProgressIndicator(),
                        //           );
                        //         } else if (snapshot.hasError) {
                        //           // Gérez les erreurs ici
                        //           return Text('Error: ${snapshot.error}');
                        //         } else {
                        //           // Les données sont prêtes, vous pouvez maintenant utiliser snapshot.data
                        //           List<TransactionModel> transactions =
                        //               snapshot.data!;
                        //           return SingleChildScrollView(
                        //             child: Padding(
                        //               padding: const EdgeInsets.symmetric(
                        //                   horizontal: 5, vertical: 5),
                        //               child: ListView.separated(
                        //                 shrinkWrap: true,
                        //                 physics: const BouncingScrollPhysics(),
                        //                 itemCount: transactions.length,
                        //                 itemBuilder: (context, index) {
                        //                   TransactionModel transac =
                        //                       transactions[index];
                        //                   return Column(
                        //                     children: [
                        //                       if (transac.statut ==
                        //                           "en attente")
                        //                         Visibility(
                        //                           visible: !visibility,
                        //                           child: TransactionTile(
                        //                               transac,
                        //                               widget.residenceSelected,
                        //                               widget.uid,
                        //                               refreshTransactions),
                        //                         ),
                        //                       if (transac.statut == "Terminé" ||
                        //                           transac.statut == "Annulé")
                        //                         Visibility(
                        //                           visible: visibility,
                        //                           child: TransactionTile(
                        //                               transac,
                        //                               widget.residenceSelected,
                        //                               widget.uid,
                        //                               refreshTransactions),
                        //                         ),
                        //                     ],
                        //                   );
                        //                 },
                        //                 separatorBuilder:
                        //                     (BuildContext context, int index) =>
                        //                         SizedBox(height: 5),
                        //               ),
                        //             ),
                        //           );
                        //         }
                        //       },
                        //     ),
                        //   ],
                        // )
                      ]);
                }
              }),
        )
      ]),
    );
  }
}
