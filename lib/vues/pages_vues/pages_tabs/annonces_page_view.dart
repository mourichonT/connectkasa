import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/pages_vues/sinistre_card.dart';
import 'package:flutter/material.dart';

class AnnoncesPageView extends StatefulWidget {
  String residenceSelected;
  String uid;
  String? argument1;

  AnnoncesPageView({
    super.key,
    required this.residenceSelected,
    required this.uid,
    this.argument1,
  });

  @override
  State<StatefulWidget> createState() => AnnoncesPageViewState();
}

class AnnoncesPageViewState extends State<AnnoncesPageView>
    with SingleTickerProviderStateMixin {
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late final TabController _tabController;
  late Future<List<Post>> _allPostsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar.secondary(
            controller: _tabController,
            tabs: <Widget>[
              const Tab(text: 'Annonces'),
              const Tab(text: 'Gérer'),
              const Tab(text: 'Validation'),
            ],
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
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: allPosts.length,
                        itemBuilder: (context, index) {
                          Post post = allPosts[index];
                          return Column(
                            children: [
                              if (post.user != widget.uid &&
                                  post.type == widget.argument1)
                                SinistreTile(post, widget.residenceSelected,
                                    widget.uid, false),
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
            Card(
              child: Text("Test2"),
            ),
            Card(
              child: Text("Test3"),
            )
          ]))
        ],
      ),
    );
  }
}
