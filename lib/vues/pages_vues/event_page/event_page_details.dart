import 'package:konodal/controllers/features/line_interaction.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/participed_button.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/enum/event_type.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/controllers/pages_controllers/my_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';

class EventPageDetails extends ConsumerStatefulWidget {
  final Post post;
  final String uid;
  final String residence;
  final Color colorStatut;
  final double scrollController;
  final bool returnHomePage;

  const EventPageDetails({
    super.key,
    required this.post,
    required this.uid,
    required this.residence,
    required this.colorStatut,
    required this.scrollController,
    required this.returnHomePage,
  });

  @override
  ConsumerState<EventPageDetails> createState() => EventPageDetailsState();
}

class EventPageDetailsState extends ConsumerState<EventPageDetails> {
  bool alreadyParticipated = false;
  int userParticipatedCount = 0;
  final IPostRepository _postServices = FirestorePostRepository();
  // Non-null seulement si cette intervention est reliée à une déclaration
  // (sinistre/incivilité) - jamais requis, d'où le CTA "Voir la déclaration
  // originale" affiché seulement quand cette Future résout un post.
  Future<Post?>? _linkedSinistreFuture;

  @override
  void initState() {
    super.initState();
    alreadyParticipated = widget.post.participants!.contains(widget.uid);
    userParticipatedCount = widget.post.participants!.length;
    final linkedSinistreId = widget.post.linkedSinistreId;
    if (linkedSinistreId != null && linkedSinistreId.isNotEmpty) {
      _linkedSinistreFuture = _postServices
          .getPost(widget.residence, linkedSinistreId)
          .then((result) => result.when(success: (v) => v, failure: (_) => null));
    }
  }

  Widget buildOrganizerInfo(AsyncValue<User?> userAsync) {
    return userAsync.when(
      loading: () => const AppLoader(),
      error: (error, stackTrace) => Text("Error: $error"),
      data: (user) {
        if (user == null) return const Text("No data found");
        return MyTextStyle.lotName(
            user.pseudo != "" ? "${user.pseudo}" : "${user.surname} ${user.name}",
            Colors.black54,
            SizeFont.h2.size);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // pathImage peut être vide (event créé sans photo, ex. depuis
              // konodal_bo) - Image.network("") lève une ArgumentError non
              // rattrapée ("No host specified in URI").
              child: (widget.post.pathImage != null &&
                      widget.post.pathImage!.isNotEmpty)
                  ? Image.network(
                      widget.post.pathImage!,
                      fit: BoxFit.fill,
                      width: width,
                      height: height / 3,
                    )
                  : imageAnnounced(context, width, height / 3),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: height / 9,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        IconButton(
                          onPressed: () async {
                            widget.returnHomePage
                                ? Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MyNavBar(
                                            uid: widget.uid,
                                            scrollController:
                                                widget.scrollController)))
                                : Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.grey.withValues(alpha: 0.20),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
            Positioned(
              top: height / 3,
              left: 0,
              right: 0,
              // bottom: 0 (absent avant ce correctif) : sans lui, ce
              // Positioned se dimensionne à la taille naturelle de son
              // contenu, sans limite - le contenu (titre, organisateur,
              // date, description, CTA) débordait donc simplement hors de
              // l'écran, inaccessible, faute de conteneur scrollable.
              bottom: 0,
              child: SingleChildScrollView(
                // Réserve la hauteur de la barre d'interaction (like/
                // commentaire/partage, Positioned séparément en bas) pour
                // que le dernier élément ne reste pas caché dessous.
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: MyTextStyle.lotName(widget.post.title,
                        Colors.black87, SizeFont.header.size),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 40),
                    child: Row(children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle),
                        child: const Icon(
                          Icons.account_tree_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        width: 1,
                        height: 40,
                        decoration: const BoxDecoration(color: Colors.black12),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              child: MyTextStyle.lotName(
                                  "Organisateur",
                                  Theme.of(context).primaryColor,
                                  SizeFont.h2.size)),
                          buildOrganizerInfo(
                              ref.watch(userByIdProvider(widget.post.user))),
                        ],
                      ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40),
                    child: Row(children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        width: 1,
                        height: 40,
                        decoration: const BoxDecoration(color: Colors.black12),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              child: MyTextStyle.lotName(
                                  MyTextStyle.completDate(
                                      widget.post.eventDate!),
                                  Theme.of(context).primaryColor,
                                  SizeFont.h2.size)),
                          Container(
                              child: MyTextStyle.lotName(
                                  widget.post.locationElement,
                                  Colors.black54,
                                  SizeFont.h2.size)),
                        ],
                      ),
                    ]),
                  ),
                  const Divider(
                    thickness: 0.5,
                    color: Colors.black12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Visibility(
                      visible: widget.post.eventType!
                          .contains(EventType.evenement.value),
                      child: PartipedTile(
                        sizeFont: SizeFont.h3.size,
                        post: widget.post,
                        residenceSelected: widget.residence,
                        uid: widget.uid,
                        space: 1,
                        number: 5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Visibility(
                      visible: widget.post.eventType!
                          .contains(EventType.prestation.value),
                      child: Row(
                        children: [
                          MyTextStyle.lotName("Prestataire :", Colors.black87,
                              SizeFont.h2.size),
                          const SizedBox(
                            width: 20,
                          ),
                          MyTextStyle.annonceDesc(widget.post.prestaName ?? "",
                              SizeFont.h3.size, 3),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 0.5,
                    color: Colors.black12,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.only(top: 0, left: 20, bottom: 20),
                        child: MyTextStyle.lotName(
                            "Description", Colors.black87, SizeFont.h2.size),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 20),
                        child: MyTextStyle.annonceDesc(
                            widget.post.description, SizeFont.h3.size, 15),
                      ),
                    ],
                  ),
                  if (_linkedSinistreFuture != null)
                    FutureBuilder<Post?>(
                      future: _linkedSinistreFuture,
                      builder: (context, snapshot) {
                        final sinistrePost = snapshot.data;
                        if (sinistrePost == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => PostView(
                                  postOrigin: sinistrePost,
                                  residence: widget.residence,
                                  uid: widget.uid,
                                  scrollController: widget.scrollController,
                                  postSelected: sinistrePost,
                                  returnHomePage: true,
                                ),
                              ));
                            },
                            child: Row(
                              children: [
                                Icon(Icons.description_outlined,
                                    color: widget.colorStatut, size: 18),
                                const SizedBox(width: 8),
                                MyTextStyle.lotName(
                                    "Voir la déclaration originale",
                                    widget.colorStatut,
                                    SizeFont.h3.size,
                                    FontWeight.w600),
                                const Spacer(),
                                Icon(Icons.chevron_right,
                                    color: widget.colorStatut, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
                ),
              ),
            ),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: iteractionLine(widget.post, widget.residence, widget.uid,
                    widget.colorStatut))
          ],
        ),
    );
  }
}
