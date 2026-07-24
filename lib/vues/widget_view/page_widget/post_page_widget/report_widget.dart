import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/pages_vues/event_page/event_page_details.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:konodal/vues/widget_view/components/comment_button.dart';
import 'package:konodal/vues/widget_view/components/expandable_description.dart';
import 'package:konodal/vues/widget_view/components/header_row.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/widget_view/components/like_button_post.dart';
import 'package:konodal/vues/widget_view/components/rounded_card.dart';
import 'package:konodal/vues/widget_view/components/share_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Affiche un post de type "rapport" (compte-rendu prestataire, créé via le
/// lien de partage - create_shared_rapport, functions_python/main.py). Basé
/// sur PostWidget, mais sans le carrousel de signalements (aucune notion de
/// doublon pour ce type) : à la place, l'intervention documentée
/// (post.linkedEventId) est affichée intégralement dans la carte, pour que
/// le lien entre les deux soit visible d'un coup d'œil, pas seulement au
/// clic. Le bouton "Commenter" pointe volontairement sur l'id de
/// l'intervention (pas celui du rapport) : le compte-rendu partage le même
/// fil de commentaires que l'intervention qu'il documente, y compris ceux
/// postés avant sa création.
class ReportWidget extends StatefulWidget {
  final Lot lot;
  final Post post;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  const ReportWidget({
    super.key,
    required this.post,
    required this.lot,
    required this.uid,
    required this.residenceSelected,
    required this.colorStatut,
    required this.scrollController,
    required this.isCsMember,
    required this.updatePostsList,
  });

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
  final IPostRepository dbService = FirestorePostRepository();
  late Future<Post?> _linkedEventFuture;

  @override
  void initState() {
    super.initState();
    final linkedEventId = widget.post.linkedEventId;
    _linkedEventFuture = (linkedEventId == null || linkedEventId.isEmpty)
        ? Future.value(null)
        : dbService
            .getPost(widget.residenceSelected, linkedEventId)
            .then((result) => result.when(
                success: (v) => v,
                // Intervention introuvable (supprimée entre-temps, id
                // invalide...) : le compte-rendu reste affichable sans son
                // bloc "Intervention" plutôt que de planter la carte entière.
                failure: (_) => null));
  }

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomHeaderRow(
              lot: widget.lot,
              post: widget.post,
              isCsMember: widget.isCsMember,
              updatePostsList: widget.updatePostsList,
            ),
            // Divider(height:) centre toujours le trait dans sa boîte (pas
            // de padding haut/bas indépendant) - trait collé en haut (pas
            // de padding top) puis un espace explicite en dessous pour
            // garder la même respiration qu'avant avec l'image.
            const Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
            const SizedBox(height: 10),
            FutureBuilder<Post?>(
              future: _linkedEventFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: AppLoader()),
                  );
                }
                final linkedEvent = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (linkedEvent != null)
                      _linkedEventBanner(context, linkedEvent),
                    // LayoutBuilder plutôt que MediaQuery.size.width : la
                    // largeur de l'écran ignore le padding horizontal du
                    // ListView (Homeview), donnant un carré plus haut que
                    // large (largeur forcée par le parent, hauteur non
                    // contrainte). constraints.maxWidth reflète la largeur
                    // réellement disponible ici.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // .ceilToDouble() : évite une fine ligne de
                        // quelques pixels non couverte sur les bords de fin
                        // (droite/bas), cf. adv_widget.dart.
                        final width = constraints.maxWidth.ceilToDouble();
                        return (widget.post.pathImage ?? '').isNotEmpty
                            ? SizedBox(
                                height: width,
                                width: width,
                                child: Image.network(
                                  widget.post.pathImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : imageAnnounced(context, width, width);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MyTextStyle.lotName(widget.post.title,
                              Colors.black87, SizeFont.h2.size),
                          const SizedBox(height: 10),
                          ExpandableDescription(
                            text: widget.post.description,
                            style: GoogleFonts.roboto(
                              fontSize: SizeFont.h3.size,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 0.6, color: Colors.black12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          LikePostButton(
                            post: widget.post,
                            residence: widget.residenceSelected,
                            uid: widget.uid,
                            colorIcon: widget.colorStatut,
                          ),
                          CommentButton(
                            // Fil de commentaires partagé avec
                            // l'intervention (cf. doc du widget) - si elle
                            // est introuvable, repli sur le rapport lui-même
                            // plutôt que de faire planter le bouton.
                            post: linkedEvent ?? widget.post,
                            residenceSelected: widget.residenceSelected,
                            uid: widget.uid,
                            colorIcon: widget.colorStatut,
                          ),
                          ShareButton(post: widget.post),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
    );
  }

  Widget _linkedEventBanner(BuildContext context, Post linkedEvent) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) => EventPageDetails(
            returnHomePage: true,
            post: linkedEvent,
            uid: widget.uid,
            residence: widget.residenceSelected,
            colorStatut: widget.colorStatut,
            scrollController: widget.scrollController,
          ),
        ));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.colorStatut.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.colorStatut.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.build_outlined, color: widget.colorStatut, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextStyle.lotName(
                    "Intervention concernée",
                    widget.colorStatut,
                    SizeFont.para.size,
                    FontWeight.w600,
                  ),
                  MyTextStyle.lotName(
                    linkedEvent.title,
                    Colors.black87,
                    SizeFont.h3.size,
                    FontWeight.normal,
                    TextOverflow.ellipsis,
                    1,
                  ),
                  if ((linkedEvent.prestaName ?? '').isNotEmpty)
                    MyTextStyle.lotName(
                      linkedEvent.prestaName!,
                      Colors.black54,
                      SizeFont.para.size,
                      FontWeight.normal,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
}
