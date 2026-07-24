import 'package:konodal/controllers/features/line_interaction.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:konodal/core/providers/post_repository_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:konodal/vues/widget_view/components/header_row.dart';
import 'package:konodal/vues/widget_view/components/rounded_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AskingNeighborsWidget extends ConsumerStatefulWidget {
  final Post post;
  final Lot lot;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  const AskingNeighborsWidget(
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
  ConsumerState<AskingNeighborsWidget> createState() => AskingNeighborsState();
}

class AskingNeighborsState extends ConsumerState<AskingNeighborsWidget> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  late Post? updatedPost;

  @override
  void initState() {
    super.initState();
    // Vue enregistrée dès l'affichage dans le fil résident (Homeview) - la
    // plupart des communications (publiées depuis le BO) n'ont jamais
    // d'image, donc pas de tap-through vers un écran détail séparé : le
    // contenu est déjà entièrement affiché ici (cf. build(), branche
    // pathImage == ""). CommunicationDetails (ouvert depuis l'onglet
    // Sinistres/Communications ou une notification) enregistre aussi sa
    // propre vue - écriture idempotente sur le même doc (vues/{uid}), pas de
    // double comptage.
    ref
        .read(postRepositoryProvider)
        .recordPostView(widget.residenceSelected, widget.post.id, widget.uid);
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
            if (widget.post.pathImage != "")
              InkWell(
                onTap: () async {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => PostView(
                      postOrigin: widget.post,
                      residence: widget.residenceSelected,
                      uid: widget.uid,
                      scrollController: widget.scrollController,
                      postSelected: widget.post,
                      returnHomePage: true,
                    ),
                  ));
                },
                child: SizedBox(
                  height: width,
                  width: width,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          widget.post.pathImage ?? "pas d'image",
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (widget.post.hideUser == false)
                        Positioned(
                          top: 0,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            width: width,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black12.withValues(
                                      alpha: 0.5), // Transparent en haut
                                  Colors.black12.withValues(
                                      alpha: 0.2), // Semi-transparent au milieu
                                  Colors.black12
                                      .withValues(alpha: 0.0), // Opaque en bas
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: profilTile(widget.post.user, 22, 19, 22,
                                  true, Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.post.pathImage == "")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.post.hideUser == true
                            ? Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    child: const CircleAvatar(
                                      radius: 19,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.visibility_off_outlined,
                                          color: Colors
                                              .black54 // Ajoutez la couleur de l'icône si nécessaire
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  MyTextStyle.lotName("Utilisateur Masqué",
                                      Colors.black87, SizeFont.h2.size),
                                ],
                              )
                            : profilTile(widget.post.user, 22, 19, 22, true,
                                Colors.black87, SizeFont.h2.size),
                        MyTextStyle.commentDate(widget.post.creationDate),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: MyTextStyle.annonceDesc(
                          widget.post.description, SizeFont.h3.size, 20),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            iteractionLine(widget.post, widget.residenceSelected, widget.uid,
                widget.colorStatut)
          ],
        ),
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
