import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/pages_vues/sinistre_card.dart';
import 'package:connect_kasa/vues/pages_vues/filter_allpost_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class SinistrePageView extends StatefulWidget {
  final String residenceSelected;
  final String uid;
  final String? argument1;
  final String? argument2;

  SinistrePageView({
    Key? key,
    required this.residenceSelected,
    required this.uid,
    this.argument1,
    this.argument2,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => SinistrePageViewState();
}

class SinistrePageViewState extends State<SinistrePageView>
    with SingleTickerProviderStateMixin {
  final DataBasesPostServices _databaseServices = DataBasesPostServices();
  late final TabController _tabController;
  late Future<List<Post>> _allPostsFuture;
  bool _showFilters = false;
  bool _selectedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allPostsFuture = _databaseServices.getAllPosts(widget.residenceSelected);
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
              residenceSelected: widget.residenceSelected,
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
                    doc: widget.residenceSelected,
                    locationElement: locationElement,
                    type: type,
                    dateFrom: dateFrom,
                    dateTo: dateTo,
                    statut: statut,
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
                    const SizedBox(width: 5),
                    MyTextStyle.lotName(
                        "Ajouter des filtres", Colors.white, 14),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Container(
              width: width,
              child: FutureBuilder<List<Post>>(
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
                    return TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          itemCount: allPosts.length,
                          itemBuilder: (context, index) {
                            final post = allPosts[index];
                            if ((post.user != widget.uid &&
                                (post.type == widget.argument1 ||
                                    post.type == widget.argument2))) {
                              return SinistreTile(
                                post,
                                widget.residenceSelected,
                                widget.uid,
                                false,
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 5),
                        ),
                        // The second tab's content should be similar or adapted as needed.
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: allPosts.length,
                          itemBuilder: (context, index) {
                            Post post = allPosts[index];
                            return Column(
                              children: [
                                if (post.user == widget.uid &&
                                    (post.type == widget.argument1 ||
                                        post.type == widget.argument2))
                                  SinistreTile(post, widget.residenceSelected,
                                      widget.uid, true),
                              ],
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 5),
                        ),
                        // Placeholder for the second tab
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
