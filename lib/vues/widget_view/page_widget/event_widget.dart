import 'package:konodal/controllers/features/line_interaction.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/participed_button.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/enum/event_type.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/pages_vues/event_page/event_page_details.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:konodal/vues/widget_view/components/header_row.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/widget_view/components/rounded_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventWidget extends StatefulWidget {
  final Lot lot;
  final Post post;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  const EventWidget(
      {super.key,
      required this.post,
      required this.lot,
      required this.uid,
      required this.residenceSelected,
      required this.colorStatut,
      required this.scrollController,
      required this.isCsMember,
      required this.updatePostsList});

  @override
  State<EventWidget> createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> {
  late Post? updatedPost;
  //bool value = false;

  late Future<List<User?>> participants;
  //late Timestamp _selectedDate;
  IPostRepository postServices = FirestorePostRepository();
  int userParticipatedCount = 0;
  // Non-null seulement si cette intervention est reliée à une déclaration
  // (sinistre/incivilité) - jamais requis (create_shared_rapport n'exige
  // aucun sinistre lié), d'où le CTA "Voir la déclaration originale"
  // affiché seulement quand cette Future résout un post.
  Future<Post?>? _linkedSinistreFuture;

  @override
  void initState() {
    super.initState();
    //_selectedDate = widget.post.eventDate!.toUtc();
    final linkedSinistreId = widget.post.linkedSinistreId;
    if (linkedSinistreId != null && linkedSinistreId.isNotEmpty) {
      _linkedSinistreFuture = postServices
          .getPost(widget.residenceSelected, linkedSinistreId)
          .then((result) => result.when(success: (v) => v, failure: (_) => null));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
            const Divider(
              height: 20,
              thickness: 0.5,
              color: Colors.black12,
            ),
            InkWell(
              onTap: () async {
                updatedPost = await postServices
                    .getUpdatePost(widget.residenceSelected, widget.post.id)
                    .then((result) => result.when(
                        success: (v) => v, failure: (_) => null));
                // Repli sur le post déjà en main (celui de la liste, déjà
                // affiché) si la relecture ne retrouve rien - notamment un
                // post écrit sans son champ "id" (ex: par konodal_bo), pour
                // qui getUpdatePost ne peut rien matcher. Sans ce repli,
                // le "!" ci-dessous plantait l'app au lieu d'ouvrir les
                // détails.
                updatedPost ??= widget.post;

                if (!context.mounted) return;
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => EventPageDetails(
                    returnHomePage: true,
                    post: updatedPost!,
                    uid: widget.uid,
                    residence: widget.residenceSelected,
                    colorStatut: widget.colorStatut,
                    scrollController: widget.scrollController,

                    // alreadyParticipated: alreadyParticipated,
                  ),
                ));
              },
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    width: width,
                    // pathImage peut être vide (event créé sans photo, ex.
                    // depuis konodal_bo) - Image.network("") lève une
                    // ArgumentError ("No host specified in URI") non
                    // rattrapée, cf. EventTileComp qui a déjà ce garde.
                    child: (widget.post.pathImage != null &&
                            widget.post.pathImage!.isNotEmpty)
                        ? Image.network(
                            widget.post.pathImage!,
                            fit: BoxFit.cover,
                          )
                        : imageAnnounced(context, width, 250),
                  ),
                  buildListTile(),
                ],
              ),
            ),
            if (_linkedSinistreFuture != null)
              FutureBuilder<Post?>(
                future: _linkedSinistreFuture,
                builder: (context, snapshot) {
                  final sinistrePost = snapshot.data;
                  if (sinistrePost == null) return const SizedBox.shrink();
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (context) => PostView(
                            postOrigin: sinistrePost,
                            residence: widget.residenceSelected,
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
                              SizeFont.para.size,
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
            iteractionLine(widget.post, widget.residenceSelected, widget.uid,
                widget.colorStatut)
          ],
        ),
    );
  }

  Widget buildListTile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.black12,
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MyTextStyle.eventDateDay(
                          widget.post.eventDate!, SizeFont.h1.size),
                      MyTextStyle.eventDateMonth(
                          widget.post.eventDate!, SizeFont.h3.size),
                    ]),
              ),
              const SizedBox(
                height: 20,
              ),
              MyTextStyle.lotDesc(
                  MyTextStyle.eventHours(widget.post.eventDate!),
                  SizeFont.h3.size,
                  FontStyle.normal),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                MyTextStyle.lotName(
                    widget.post.title, Colors.black87, SizeFont.h2.size),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: MyTextStyle.annonceDesc(
                      widget.post.description, SizeFont.h3.size, 3),
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: widget.post.eventType!
                      .contains(EventType.evenement.value),
                  child: PartipedTile(
                    sizeFont: SizeFont.h3.size,
                    post: widget.post,
                    residenceSelected: widget.residenceSelected,
                    uid: widget.uid,
                    space: 0.5,
                    number: 5,
                  ),
                ),
                Visibility(
                  visible: widget.post.eventType!
                      .contains(EventType.prestation.value),
                  child: Row(
                    children: [
                      MyTextStyle.lotName(
                          "Prestataire :", Colors.black87, SizeFont.h2.size),
                      const SizedBox(
                        width: 20,
                      ),
                      MyTextStyle.annonceDesc(
                          widget.post.prestaName ?? "", SizeFont.h3.size, 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<List<String>> typeList = TypeList().typeDeclaration();

  String getType(Post post) {
    for (var type in typeList) {
      var typeName = type[0];
      var typeValue = type[1];
      if (post.type == typeValue) {
        return typeName;
      }
    }
    return '';
  }
}
