import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/transaction_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/transaction.dart';
import 'package:connect_kasa/vues/pages_vues/annonce_tile.dart';
import 'package:connect_kasa/vues/widget_view/transaction_tile.dart';
import 'package:flutter/material.dart';

class AnnoncesPageView extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final String? type;
  final Color colorStatut;
  final double scrollController;

  AnnoncesPageView({
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allPostsFuture =
        _databaseServices.getAllAnnonces(widget.residenceSelected);
    _allTransaction = _transacServices.getTransactionByUid(
        widget.uid, widget.residenceSelected);
    _tabController.addListener(_handleTabChange);

    _selectedTab = _tabController.index == 0;
  }

  void _handleTabChange() {
    setState(() {
      _selectedTab = _tabController.index ==
          0; // Met à jour _showFilters en fonction de l'onglet actuellement sélectionné
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar.secondary(
            controller: _tabController,
            tabs: <Widget>[
              const Tab(text: 'Tous'),
              const Tab(text: 'Mes annonces'),
              const Tab(text: 'Mes transactions'),
            ],
          ),
          if (_showFilters &&
              _selectedTab) // Affichage conditionnel des filtres
            Container(
              width: width,
              height: 100,
              color: Colors.white,
              padding: EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // Ajoutez vos filtres ici
                  // Par exemple, des dropdowns pour post.type, post.timestamp, etc.
                ],
              ),
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
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      MyTextStyle.lotName(
                          "Ajouter des filtres", Colors.white, 14)
                    ],
                  )),
            ),
          Expanded(
              child: TabBarView(controller: _tabController, children: <Widget>[
            FutureBuilder<List<Post>>(
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
                  return GridView.builder(
                    itemCount: allPosts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 4,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      // Assurez-vous que l'index est valide avant d'accéder à la liste
                      if (index < allPosts.length) {
                        Post post = allPosts[index];
                        // Vérifiez votre condition ici
                        if (post.user != widget.uid &&
                            post.type == widget.type) {
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
                  );
                }
              },
            ),
            Card(
              child: Text("Test2"),
            ),
            FutureBuilder<List<TransactionModel>>(
              future: _allTransaction,
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
                  List<TransactionModel> transactions = snapshot.data!;
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          TransactionModel transac = transactions[index];
                          return Column(
                            children: [
                              // if (post.user != widget.uid &&
                              //     post.type == widget.argument1)
                              TransactionTile(transac, widget.residenceSelected,
                                  widget.uid),
                            ],
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            SizedBox(height: 5),
                      ),
                    ),
                  );
                }
              },
            ),
          ]))
        ],
      ),
    );
  }
}
