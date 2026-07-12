import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/widgets_controllers/sinitres_tile_controller.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/core/providers/post_repository_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/pages_vues/post_page/sinistre_tile.dart';
import 'package:konodal/controllers/pages_controllers/filter_allpost_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class SinistrePageView extends ConsumerStatefulWidget {
  final String residenceId;
  final String uid;
  final Color colorStatut;
  final String? argument1;
  final String? argument2;
  final String? argument3;

  const SinistrePageView({
    super.key,
    required this.residenceId,
    required this.uid,
    required this.colorStatut,
    this.argument1,
    this.argument2,
    this.argument3,
  });

  @override
  ConsumerState<SinistrePageView> createState() => SinistrePageViewState();
}

class SinistrePageViewState extends ConsumerState<SinistrePageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _postsScrollController;
  late final ScrollController _signalementsScrollController;
  bool _showFilters = false;
  bool _selectedTab = false;

  /// Résultat de FilterAllPostController, en remplacement de la liste non
  /// filtrée le temps qu'un nouveau filtre soit actif. `null` = pas de
  /// filtre, on affiche postsByResidenceProvider tel quel. Les résultats
  /// filtrés ne sont pas paginés (hasMore: false) : getAllPostsWithFilters
  /// n'a pas de variante paginée, cohérent avec le comportement d'origine.
  AsyncValue<PaginatedPosts>? _filteredPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _selectedTab = _tabController.index == 0;
    _postsScrollController = ScrollController()
      ..addListener(() {
        if (_postsScrollController.position.pixels >=
            _postsScrollController.position.maxScrollExtent - 300) {
          ref
              .read(postsByResidenceProvider(widget.residenceId).notifier)
              .loadMore();
        }
      });
    _signalementsScrollController = ScrollController()
      ..addListener(() {
        if (_signalementsScrollController.position.pixels >=
            _signalementsScrollController.position.maxScrollExtent - 300) {
          ref
              .read(signalementsByResidenceProvider(widget.residenceId)
                  .notifier)
              .loadMore();
        }
      });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _postsScrollController.dispose();
    _signalementsScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _selectedTab = _tabController.index == 0;
    });
  }

  /// Rafraîchit les deux onglets depuis l'extérieur (ex: my_nav_bar.dart au
  /// retour du formulaire de création/modification de post), via un
  /// `GlobalKey<SinistrePageViewState>`. Revient à la liste non filtrée,
  /// comme le faisait déjà la version précédente de cette méthode.
  void updatePostsList() {
    ref.invalidate(postsByResidenceProvider(widget.residenceId));
    ref.invalidate(signalementsByResidenceProvider(widget.residenceId));
    setState(() {
      _filteredPosts = null;
    });
  }

  Future<void> _applyFilters({
    required List<String?> locationElement,
    required List<String?> type,
    required String dateFrom,
    required String dateTo,
    required List<String?> statut,
  }) async {
    setState(() {
      _filteredPosts = const AsyncValue.loading();
    });
    final repository = ref.read(postRepositoryProvider);
    final result = await repository.getAllPostsWithFilters(
      doc: widget.residenceId,
      locationElement: locationElement,
      type: type,
      dateFrom: dateFrom,
      dateTo: dateTo,
      statut: statut,
    );
    if (!mounted) return;
    setState(() {
      _filteredPosts = result.when(
        success: (v) =>
            AsyncValue.data(PaginatedPosts(posts: v, hasMore: false)),
        failure: (error) => AsyncValue.error(error, StackTrace.current),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;
    final AsyncValue<PaginatedPosts> postsAsync = _filteredPosts ??
        ref.watch(postsByResidenceProvider(widget.residenceId));
    final signalementsAsync =
        ref.watch(signalementsByResidenceProvider(widget.residenceId));

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
                onFilterUpdate: _applyFilters,
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
                        "Ajouter des filtres", Colors.white, SizeFont.h3.size),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SizedBox(
              width: width,
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  postsAsync.when(
                    loading: () =>
                        const Center(child: AppLoader()),
                    error: (error, stackTrace) => Text('Error: $error'),
                    data: (paginated) {
                      final allPosts = paginated.posts;
                      return ListView.separated(
                        controller: _postsScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        itemCount:
                            allPosts.length + (paginated.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= allPosts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: AppLoader()),
                            );
                          }
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
                    },
                  ),
                  signalementsAsync.when(
                    loading: () =>
                        const Center(child: AppLoader()),
                    error: (error, stackTrace) => Text('Error: $error'),
                    data: (paginated) {
                      final allPosts = paginated.posts;
                      return ListView.separated(
                        controller: _signalementsScrollController,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount:
                            allPosts.length + (paginated.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= allPosts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: AppLoader()),
                            );
                          }
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
