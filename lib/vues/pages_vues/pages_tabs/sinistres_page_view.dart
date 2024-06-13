import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/pages_controllers/sinitres_tile_controller.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/pages_vues/sinistre_tile.dart';
import 'package:connect_kasa/controllers/pages_controllers/filter_allpost_controller.dart';
import 'package:flutter/material.dart';

class SinistrePageView extends StatefulWidget {
  final String residenceId;
  final String uid;
  final Color colorStatut;
  final String? argument1;
  final String? argument2;
  final String? argument3;

  SinistrePageView({
    Key? key,
    required this.residenceId,
    required this.uid,
    required this.colorStatut,
    this.argument1,
    this.argument2,
    this.argument3,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SinistrePageViewState();
}

class SinistrePageViewState extends State<SinistrePageView>
    with SingleTickerProviderStateMixin {
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late final TabController _tabController;
  late Future<List<Post>> _allPostsFuture;
  late Future<List<Post>> _allSignalementFuture;
  bool _showFilters = false;
  bool _selectedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceId);
    _allSignalementFuture =
        _databaseServices.getAllPostsToModify(widget.residenceId);
    _tabController.addListener(_handleTabChange);
    _selectedTab = _tabController.index == 0;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _selectedTab = _tabController.index == 0;
    });
  }

  void updatePostsList() {
    setState(() {
      _allPostsFuture = _databaseServices.getAllPosts(widget.residenceId);
      _allSignalementFuture =
          _databaseServices.getAllPostsToModify(widget.residenceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Toutes'),
              Tab(text: 'Mes déclarations'),
            ],
          ),
          if (_showFilters && _selectedTab)
            FilterAllPostController(
                residenceSelected: widget.residenceId,
                uid: widget.uid,
                onFilterUpdate: ({
                  required List<String?> locationElement,
                  required List<String?> type,
                  required String dateFrom,
                  required String dateTo,
                  required List<String?> statut,
                }) {
                  setState(() {
                    _allPostsFuture = _databaseServices.getAllPostsWithFilters(
                      doc: widget.residenceId,
                      locationElement: locationElement,
                      type: type,
                      dateFrom: dateFrom,
                      dateTo: dateTo,
                      statut: statut,
                    );
                  });
                },
                updateShowFilter: ({required bool showFilter}) {
                  setState(() {
                    _showFilters = showFilter;
                  });
                }),
          if (_selectedTab)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              child: Container(
                width: width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                    MyTextStyle.lotName(
                        "Ajouter des filtres", Colors.white, 14),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Container(
              width: width,
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  FutureBuilder<List<Post>>(
                    future: _allPostsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        List<Post> allPosts = snapshot.data!;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          itemCount: allPosts.length,
                          itemBuilder: (context, index) {
                            final post = allPosts[index];
                            if ((post.type == widget.argument1 ||
                                post.type == widget.argument2 ||
                                post.type == widget.argument3)) {
                              return SinitresTileController(
                                post: post,
                                residenceId: widget.residenceId,
                                uid: widget.uid,
                                colorStatut: widget.colorStatut,
                                canModify: false,
                                updatePostsList: updatePostsList,
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 0),
                        );
                      }
                    },
                  ),
                  FutureBuilder<List<Post>>(
                    future: _allSignalementFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        List<Post> allPosts = snapshot.data!;
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: allPosts.length,
                          itemBuilder: (context, index) {
                            Post post = allPosts[index];
                            return Column(
                              children: [
                                if (post.user == widget.uid &&
                                    (post.type == widget.argument1 ||
                                        post.type == widget.argument2 ||
                                        post.type == widget.argument3))
                                  SinistreTile(
                                    post,
                                    widget.residenceId,
                                    widget.uid,
                                    true,
                                    widget.colorStatut,
                                    updatePostsList,
                                  ),
                              ],
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 0),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
