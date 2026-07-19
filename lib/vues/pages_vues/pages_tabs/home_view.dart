// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'dart:async';
import 'package:konodal/core/providers/ad_campaign_providers.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/page_widget/post_page_widget/adv_widget.dart';
import 'package:konodal/vues/widget_view/page_widget/post_page_widget/asking_neighbors_widget.dart';
import 'package:konodal/vues/widget_view/page_widget/event_widget.dart';
import 'package:konodal/vues/widget_view/page_widget/annonce_page_widget/annonce_widget.dart';
import 'package:konodal/vues/widget_view/page_widget/post_page_widget/post_widget.dart';
import 'package:konodal/vues/widget_view/page_widget/post_page_widget/report_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class Homeview extends ConsumerStatefulWidget {
  String residenceSelected;
  String uid;
  double? upDatescrollController;
  Color colorStatut;
  final Function updatePostsList;
  final Lot preferedLot;
  final bool isCsMember;

  Homeview({
    super.key,
    required this.residenceSelected,
    required this.uid,
    this.upDatescrollController,
    required this.colorStatut,
    required this.updatePostsList,
    required this.preferedLot,
    required this.isCsMember,
  });

  @override
  HomeviewState createState() => HomeviewState();
}

class HomeviewState extends ConsumerState<Homeview> {
  late ScrollController _scrollController;
  double scrollPosition = 0.0;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.upDatescrollController ?? 0,
    );
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (mounted) {
      setState(() {
        scrollPosition = _scrollController.offset;
      });
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref
          .read(postsByResidenceProvider(widget.residenceSelected).notifier)
          .loadMore();
    }
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(postsByResidenceProvider(widget.residenceSelected));
    await ref.read(postsByResidenceProvider(widget.residenceSelected).future);
  }

  /// Rafraîchit la liste depuis l'extérieur (ex: my_nav_bar.dart au retour
  /// du formulaire de création de post), via un `GlobalKey<HomeviewState>`.
  Future<void> refreshPosts() => _handleRefresh();

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// Nombre de groupes complets de taille [groupSize] contenus dans
  /// [count]. Sert deux fois dans le calcul d'intercalation des pubs :
  /// une fois pour compter combien de pubs au total tiennent dans les posts
  /// déjà chargés (groupSize = frequency), une fois pour retrouver, à partir
  /// d'un index dans la liste combinée posts+pubs, combien de pubs le
  /// précèdent (groupSize = frequency + 1).
  int _completeGroupsIn(int count, int groupSize) {
    if (groupSize <= 0) return 0;
    return count ~/ groupSize;
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync =
        ref.watch(postsByResidenceProvider(widget.residenceSelected));
    final campaign =
        ref.watch(activeAdCampaignProvider(widget.residenceSelected)).valueOrNull;
    final frequency = campaign?.displayFrequency ?? 0;

    return paginatedAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Text('Erreur: $error'),
      data: (paginated) {
        final allPosts = paginated.posts;
        if (allPosts.isEmpty) {
          // residenceSelected encore vide le temps que my_nav_bar.dart
          // résolve le vrai lot (placeholder _defaultLot au tout premier
          // build) : pas encore "aucun post", juste pas encore chargé.
          if (widget.residenceSelected.isEmpty) {
            return const Center(child: AppLoader());
          }
          return const Center(
            child: Text("Aucun post n'a été publié pour le moment"),
          );
        } else {
          // Une pub s'intercale après chaque groupe complet de [frequency]
          // posts réels (groupe de taille frequency + 1 dans la liste
          // combinée) - cf. _completeGroupsIn. Pas de pub insérée après un
          // groupe incomplet en fin de liste (les posts pas encore chargés
          // au scroll suivant complèteront le groupe).
          final totalAdSlots = campaign != null
              ? _completeGroupsIn(allPosts.length, frequency)
              : 0;
          final totalItems =
              allPosts.length + totalAdSlots + (paginated.hasMore ? 1 : 0);

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: totalItems,
              padding: const EdgeInsets.only(
                  top: 30, bottom: 120, right: 10, left: 10),
              separatorBuilder: (context, index) => const SizedBox(height: 30),
              itemBuilder: (context, index) {
                if (campaign != null && frequency > 0) {
                  final groupSize = frequency + 1;
                  if (index % groupSize == frequency) {
                    return AdvWidget(campaign: campaign);
                  }
                  index -= _completeGroupsIn(index, groupSize);
                }
                if (index >= allPosts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: AppLoader()),
                  );
                }
                Post post = allPosts[index];
                return Column(
                  children: [
                    if (post.type == "sinistres" || post.type == "incivilites")
                      PostWidget(
                        widget.preferedLot,
                        post,
                        widget.residenceSelected,
                        widget.uid,
                        scrollPosition,
                        widget.isCsMember,
                        widget.updatePostsList,
                      ),
                    if (post.type == "rapport")
                      ReportWidget(
                        post: post,
                        lot: widget.preferedLot,
                        uid: widget.uid,
                        residenceSelected: widget.residenceSelected,
                        colorStatut: widget.colorStatut,
                        scrollController: scrollPosition,
                        isCsMember: widget.isCsMember,
                        updatePostsList: widget.updatePostsList,
                      ),
                    if (post.type == "annonces")
                      AnnonceWidget(
                        lot: widget.preferedLot,
                        post: post,
                        uid: widget.uid,
                        residenceSelected: widget.residenceSelected,
                        colorStatut: widget.colorStatut,
                        scrollController: scrollPosition,
                        isCsMember: widget.isCsMember,
                        updatePostsList: widget.updatePostsList,
                      ),
                    if (post.type == "events")
                      EventWidget(
                        lot: widget.preferedLot,
                        post: post,
                        uid: widget.uid,
                        residenceSelected: widget.residenceSelected,
                        colorStatut: widget.colorStatut,
                        scrollController: scrollPosition,
                        isCsMember: widget.isCsMember,
                        updatePostsList: widget.updatePostsList,
                      ),
                    if (post.type == "communication")
                      AskingNeighborsWidget(
                        lot: widget.preferedLot,
                        post: post,
                        uid: widget.uid,
                        residenceSelected: widget.residenceSelected,
                        colorStatut: widget.colorStatut,
                        scrollController: scrollPosition,
                        isCsMember: widget.isCsMember,
                        updatePostsList: widget.updatePostsList,
                      ),
                  ],
                );
              },
            ),
          );
        }
      },
    );
  }
}
