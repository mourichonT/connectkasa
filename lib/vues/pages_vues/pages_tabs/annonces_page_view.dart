import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/pages_controllers/filter_allannounced_controller..dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/transaction_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/annonces_page/add_annonceform.dart';
import 'package:connect_kasa/vues/widget_view/components/annonce_tile.dart';
import 'package:connect_kasa/vues/pages_vues/post_page/sinistre_tile.dart';
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
      _selectedTab = _tabController.index == 0;
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
      length: 2,
      child: Column(children: <Widget>[
        TabBar.secondary(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Tous'),
            Tab(text: 'Gérer'),
          ],
        ),
        if (_showFilters && _selectedTab)
          FilterAllAnnouncedController(
            residenceSelected: widget.residenceSelected,
            uid: widget.uid,
            onFilterUpdate: ({
              required List<String?> categorie,
              required String dateFrom,
              required String dateTo,
              required int priceMin,
              required int priceMax,
            }) {
              setState(() {
                _allPostsFuture = _databaseServices.getAllAnnoncesWithFilters(
                  doc: widget.residenceSelected,
                  subtype: categorie,
                  dateFrom: dateFrom,
                  dateTo: dateTo,
                  priceMin: priceMin,
                  priceMax: priceMax,
                );
              });
            },
          ),
        if (_selectedTab)
          GestureDetector(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              color: color,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  MyTextStyle.lotName(
                    "Ajouter des filtres",
                    Colors.white,
                    SizeFont.h3.size,
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Post>>(
            future: _allPostsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Erreur : ${snapshot.error}');
              } else {
                final allPosts = snapshot.data!;
                return TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    // Onglet "Tous"
                    GridView.builder(
                      padding: const EdgeInsets.only(top: 20, bottom: 100),
                      physics: BouncingScrollPhysics(),
                      itemCount: allPosts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2 / 3,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        if (index < allPosts.length) {
                          Post post = allPosts[index];
                          if (post.type == widget.type) {
                            return AnnonceTile(
                              post,
                              widget.residenceSelected,
                              widget.uid,
                              false,
                              widget.colorStatut,
                              widget.scrollController,
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    // Onglet "Gérer"
                    ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      itemCount: allPosts.length + 1, // +1 pour le bouton
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 90,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 10, bottom: 10, left: 20, right: 10),
                              child: ButtonAdd(
                                function: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => AddAnnonceForm(
                                        residence: widget.residenceSelected,
                                        uid: widget.uid,
                                      ),
                                    ),
                                  );
                                },
                                color: color,
                                icon: Icons.add,
                                text: 'Ajouter une annonce',
                                horizontal: 10,
                                vertical: 10,
                                size: SizeFont.h3.size,
                              ),
                            ),
                          );
                        }

                        final post = allPosts[index - 1];
                        if (post.user == widget.uid) {
                          return SinistreTile(
                            post,
                            widget.residenceSelected,
                            widget.uid,
                            true,
                            widget.colorStatut,
                            updatePostsList,
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 0),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ]),
    );
  }
}
