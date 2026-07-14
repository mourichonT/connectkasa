// ignore_for_file: must_be_immutable

import 'package:konodal/controllers/features/line_interaction.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/controllers/widgets_controllers/signalement_count_controller.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/header_row.dart';
import 'package:konodal/vues/widget_view/page_widget/post_page_widget/signalement_tile.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../../../../../models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class PostWidget extends StatefulWidget {
  final Lot lot;
  late Post post;
  final String uid;
  final String residence;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  PostWidget(this.lot, this.post, this.residence, this.uid,
      this.scrollController, this.isCsMember, this.updatePostsList,
      {super.key});
  @override
  State<StatefulWidget> createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  late Future<List<Post>> _signalementFuture;
  IPostRepository dbService = FirestorePostRepository();
  List<List<String>> typeList = TypeList().typeDeclaration();
  int postCount = 0;
  int likeCount = 0;
  @override
  void initState() {
    super.initState();
    //likeCount = widget.post.like.length;
    // getSignalementsList ne renvoie QUE les signalements imbriqués (pas
    // le post lui-même, contrairement à getSignalements) : widget.post
    // est déjà disponible directement, pas besoin de le re-télécharger.
    // Ça évite aussi que le post entier devienne invisible (carrousel
    // vide) si cette requête échoue ou ne trouve rien.
    _signalementFuture = dbService
        .getSignalementsList(widget.residence, widget.post.id)
        .then((result) =>
            result.when(success: (v) => v, failure: (error) => throw error));
  }

  @override
  Widget build(BuildContext context) {
    Color colorStatut = Theme.of(context).primaryColor;
    double width = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomHeaderRow(
                lot: widget.lot,
                post: widget.post,
                colorStatut: colorStatut,
                isCsMember: widget.isCsMember,
                updatePostsList: widget.updatePostsList),
            const Divider(
              height: 20,
              thickness: 0.5,
            ),
            FutureBuilder<List<Post>>(
              future: _signalementFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoader());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  // widget.post en premier (toujours disponible, jamais
                  // dépendant de la requête), suivi des vrais signalements
                  // imbriqués trouvés (doublons détectés par la Cloud
                  // Function). postCount inclut le post lui-même, pour
                  // garder le même comptage "N signalement(s)" qu'avant.
                  List<Post> nestedSignalements = snapshot.data!;
                  List<Post> signalements = [widget.post, ...nestedSignalements];
                  postCount = signalements.length;
                  return Column(
                    children: [
                      FlutterCarousel(
                        options: FlutterCarouselOptions(
                          viewportFraction: 1.0,
                          pageSnapping: true,
                          showIndicator: true,
                          floatingIndicator: true,
                          slideIndicator: CircularSlideIndicator(
                              slideIndicatorOptions: SlideIndicatorOptions(
                                  indicatorRadius: 5,
                                  indicatorBackgroundColor: Colors.black12,
                                  currentIndicatorColor: colorStatut,
                                  itemSpacing: 13)),
                        ),
                        items: signalements.map((postSelected) {
                          return InkWell(
                            onTap: () {
                              // postSelected est déjà disponible (c'est ce qui
                              // affiche cette tuile) - pas besoin d'attendre
                              // une requête Firestore avant d'ouvrir le
                              // détail (l'ancien FutureBuilder bloquait
                              // l'ouverture derrière un loader plein écran,
                              // surtout gênant pour une vidéo qui a déjà son
                              // propre temps de chargement réseau). Le
                              // rafraîchissement au retour (PopScope) reste
                              // inchangé.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PopScope(
                                    onPopInvokedWithResult:
                                        (didPop, result) async {
                                      Post? postChanges = await dbService
                                          .getUpdatePost(
                                              widget.residence, widget.post.id)
                                          .then((result) => result.when(
                                              success: (v) => v,
                                              failure: (_) => null));

                                      if (postChanges != null && mounted) {
                                        setState(() {
                                          widget.post = postChanges;
                                        });
                                      }
                                    },
                                    child: PostView(
                                      postOrigin: postSelected,
                                      residence: widget.residence,
                                      uid: widget.uid,
                                      scrollController:
                                          widget.scrollController,
                                      postSelected: postSelected,
                                      returnHomePage: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: SignalementTile(
                                postSelected,
                                width,
                                postCount,
                                (count) {
                                  postCount = count;
                                },
                                widget.residence,
                                widget.uid,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SignalementsCountController(
                          post: widget.post, postCount: postCount),
                    ],
                  );
                }
              },
            ),
            iteractionLine(
                widget.post, widget.residence, widget.uid, colorStatut)
          ],
        ),
      ),
    );
  }
}
