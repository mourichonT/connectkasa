// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:konodal/core/providers/ad_campaign_providers.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/models/pages_models/ad_campaign.dart';
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

  /// Statut du résident courant sur son lot préféré (idProprietaire/
  /// idLocataire du Lot, pas un champ direct) - remonté avec chaque
  /// impression/clic pub pour le rapport de campagne (engagement par profil
  /// propriétaire/locataire, cf. AdCampaignDetailPage côté BO).
  String get _statutResident {
    if (widget.preferedLot.idProprietaire?.contains(widget.uid) == true) {
      return "Propriétaire";
    }
    if (widget.preferedLot.idLocataire?.contains(widget.uid) == true) {
      return "Locataire";
    }
    return "Inconnu";
  }

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

  // Ordre (ids) dans lequel les campagnes actives tournent aux emplacements
  // pub - mélangé une seule fois par session (pas à chaque rebuild, sinon
  // le simple fait d'incrémenter impressionCount/clickCount, qui refait
  // émettre le stream Firestore, rebattrait les cartes en permanence).
  // Recalculé seulement si l'ensemble des campagnes actives change (ajout/
  // retrait côté BO), jamais pour une simple mise à jour de compteurs.
  List<String>? _shuffledCampaignOrder;

  List<AdCampaign> _orderedCampaigns(List<AdCampaign> campaigns) {
    final currentIds = campaigns.map((c) => c.id).toSet();
    final knownIds = _shuffledCampaignOrder?.toSet();
    if (_shuffledCampaignOrder == null || !setEquals(knownIds, currentIds)) {
      _shuffledCampaignOrder = campaigns.map((c) => c.id).toList()
        ..shuffle(Random());
    }
    final byId = {for (final c in campaigns) c.id: c};
    return _shuffledCampaignOrder!
        .map((id) => byId[id])
        .whereType<AdCampaign>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync =
        ref.watch(postsByResidenceProvider(widget.residenceSelected));
    final campaigns = _orderedCampaigns(
        ref.watch(activeAdCampaignsProvider(widget.residenceSelected)).valueOrNull ??
            const []);
    // Fréquence d'affichage : réglage global partagé par toutes les
    // campagnes (plus un champ par campagne), cf. AdCampaignConfig.
    final frequency = campaigns.isEmpty
        ? 0
        : ref.watch(adCampaignConfigProvider).valueOrNull?.displayFrequency ?? 0;

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
          final totalAdSlots = campaigns.isNotEmpty
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
                if (campaigns.isNotEmpty && frequency > 0) {
                  final groupSize = frequency + 1;
                  if (index % groupSize == frequency) {
                    // Rotation round-robin sur l'ordre mélangé une fois par
                    // session (_shuffledCampaignOrder) : le K-ème emplacement
                    // pub (K=0,1,2...) prend la campagne à l'index K modulo
                    // le nombre de campagnes actives, pour ne jamais montrer
                    // la même deux fois de suite quand il y en a plusieurs.
                    final adSlotIndex = index ~/ groupSize;
                    final campaign =
                        campaigns[adSlotIndex % campaigns.length];
                    return AdvWidget(
                      campaign: campaign,
                      residenceId: widget.residenceSelected,
                      uid: widget.uid,
                      statutResident: _statutResident,
                    );
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
