import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/pages_controllers/filter_allannounced_controller.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/pages_vues/annonces_page/add_annonceform.dart';
import 'package:konodal/vues/widget_view/components/annonce_tile.dart';
import 'package:konodal/vues/pages_vues/post_page/sinistre_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class AnnoncesPageView extends ConsumerStatefulWidget {
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
  ConsumerState<AnnoncesPageView> createState() => AnnoncesPageViewState();
}

class AnnoncesPageViewState extends ConsumerState<AnnoncesPageView>
    with SingleTickerProviderStateMixin {
  final IPostRepository _databaseServices = FirestorePostRepository();
  late final TabController _tabController;
  bool _showFilters = false;
  bool _selectedTab = false;
  bool colorSelection = false;
  Color colorSelected = Colors.white;
  bool visibility = false;

  /// Résultat de FilterAllAnnouncedController, en remplacement de la liste
  /// non filtrée le temps qu'un nouveau filtre soit actif. `null` = pas de
  /// filtre, on affiche annoncesByResidenceProvider tel quel.
  AsyncValue<List<Post>>? _filteredPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _selectedTab = _tabController.index == 0;
  }

  void _handleTabChange() {
    setState(() {
      _selectedTab = _tabController.index == 0;
    });
  }

  void updatePostsList() {
    ref.invalidate(annoncesByResidenceProvider(widget.residenceSelected));
    setState(() {
      _filteredPosts = null;
    });
  }

  Future<void> _applyFilters({
    required List<String?> categorie,
    required String dateFrom,
    required String dateTo,
    required int priceMin,
    required int priceMax,
  }) async {
    setState(() {
      _filteredPosts = const AsyncValue.loading();
    });
    final result = await _databaseServices.getAllAnnoncesWithFilters(
      doc: widget.residenceSelected,
      subtype: categorie,
      dateFrom: dateFrom,
      dateTo: dateTo,
      priceMin: priceMin,
      priceMax: priceMax,
    );
    if (!mounted) return;
    setState(() {
      _filteredPosts = result.when(
        success: (v) => AsyncValue.data(v),
        failure: (error) => AsyncValue.error(error, StackTrace.current),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    final double width = MediaQuery.of(context).size.width;
    final AsyncValue<List<Post>> postsAsync = _filteredPosts ??
        ref.watch(annoncesByResidenceProvider(widget.residenceSelected));

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
            onFilterUpdate: _applyFilters,
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
          child: postsAsync.when(
            loading: () => const Center(child: AppLoader()),
            error: (error, stackTrace) => Text('Erreur : $error'),
            data: (allPosts) {
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
                              function: () async {
                                await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => AddAnnonceForm(
                                      residence: widget.residenceSelected,
                                      uid: widget.uid,
                                    ),
                                  ),
                                );
                                // Rafraîchit la liste au retour du
                                // formulaire, sinon l'annonce ajoutée
                                // n'apparaît pas tant que l'écran
                                // n'est pas rechargé.
                                if (mounted) updatePostsList();
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
            },
          ),
        ),
      ]),
    );
  }
}
