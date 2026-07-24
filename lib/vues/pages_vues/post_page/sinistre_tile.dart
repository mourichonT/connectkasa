import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/agent_agency_name_provider.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/core/repositories/firestore_storage_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/expandable_description.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/widget_view/components/network_video_player.dart';
import 'package:konodal/vues/pages_vues/annonces_page/annonce_page_details.dart';
import 'package:konodal/vues/pages_vues/post_page/communication_detail.dart';
import 'package:konodal/vues/pages_vues/annonces_page/modify_annonceform.dart';
import 'package:konodal/vues/pages_vues/post_page/modify_asking_neighbors_form.dart';
import 'package:konodal/vues/pages_vues/post_page/modify_postform.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class SinistreTile extends StatefulWidget {
  late Post post;
  final String uid;
  final String residenceId;
  final bool canModify;
  final Color colorStatut;
  final Function()? updatePostsList;

  SinistreTile(this.post, this.residenceId, this.uid, this.canModify,
      this.colorStatut, this.updatePostsList,
      {super.key});

  @override
  State<StatefulWidget> createState() => SinistreTileState();
}

class SinistreTileState extends State<SinistreTile> {
  final FirestoreStorageRepository _storageServices = FirestoreStorageRepository();
  IPostRepository dbService = FirestorePostRepository();
  List<List<String>> typeList = TypeList().typeDeclaration();
  String url = "";

  int postCount = 0;

  String getType(Post post) {
    for (var type in typeList) {
      var typeName = type[0];
      var typeValue = type[1];
      if (widget.post.type == typeValue) {
        return typeName;
      }
    }
    return '';
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          // widget.post est déjà disponible immédiatement (c'est ce qui
          // affiche cette tuile) - pas besoin d'attendre une requête
          // Firestore avant d'ouvrir le détail (l'ancien FutureBuilder
          // bloquait l'ouverture derrière un loader plein écran pour
          // rien : les deux branches de son résultat affichaient de
          // toute façon widget.post, jamais la valeur récupérée).
          // Le rafraîchissement au retour (PopScope) reste inchangé.
          builder: (context) => PopScope(
                onPopInvokedWithResult: (didPop, result) async {
                  Post? postChanges = await dbService
                      .getUpdatePost(widget.residenceId, widget.post.id)
                      .then((result) => result.when(
                          success: (v) => v, failure: (_) => null));

                  if (postChanges != null && mounted) {
                    setState(() {
                      widget.post = postChanges;
                    });
                  }
                },
                child: Builder(builder: (context) {
                  if (widget.post.type == "sinistres" ||
                      widget.post.type == "incivilites") {
                    return PostView(
                      postOrigin: widget.post,
                      residence: widget.residenceId,
                      uid: widget.uid,
                      postSelected: widget.post,
                      returnHomePage: false,
                    );
                  } else if (widget.post.type == "communication") {
                    return CommunicationDetails(
                      uid: widget.uid,
                      post: widget.post,
                      residenceId: widget.residenceId,
                    );
                  } else {
                    return AnnoncePageDetails(
                      returnHomePage: false,
                      post: widget.post,
                      uid: widget.uid,
                      residence: widget.residenceId,
                      colorStatut: widget.colorStatut,
                    );
                  }
                }),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10, vertical: 10),
            width: MediaQuery.of(context).size.width * 0.95,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GestureDetector limité à la zone image+texte (Expanded) -
                // les boutons modifier/supprimer ci-dessous restent EN
                // DEHORS, comme siblings du Row : les y imbriquer risquait
                // de faire gagner l'arène de gestes au tap parent et
                // d'ouvrir le détail au lieu de modifier/supprimer.
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openDetails(context),
                    child: Row(
                      children: [
                        if (widget.post.pathImage != "" &&
                            widget.post.pathImage != null &&
                            widget.post.pathImage!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: 120,
                              height: 120,
                              child: widget.post.isVideo
                                  ? Stack(
                                      alignment: Alignment.center,
                                      // Sans ça, le Stack se redimensionne au
                                      // ratio de la vidéo (StackFit.loose,
                                      // par défaut) au lieu de remplir toute
                                      // la case 120x120 dédiée.
                                      fit: StackFit.expand,
                                      children: [
                                        NetworkVideoPlayer(
                                          url: widget.post.pathImage!,
                                          showControls: false,
                                        ),
                                        const Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white70,
                                          size: 36,
                                        ),
                                      ],
                                    )
                                  : Image.network(
                                      widget.post.pathImage!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              width: 120,
                              height: 120,
                              child: imageAnnounced(context, 120, 120),
                            ),
                          ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.post.type != "annonces")
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    MyTextStyle.postDesc(getType(widget.post),
                                        SizeFont.para.size, Colors.black87),
                                    if (!widget.post.hideUser)
                                      if (!widget.canModify)
                                        Consumer(
                                            builder: (context, ref, child) {
                                          final userAsync = ref.watch(
                                              userByIdProvider(
                                                  widget.post.user));
                                          final user = userAsync.valueOrNull;
                                          if (user != null) {
                                            return widget.post.user ==
                                                    widget.uid
                                                ? MyTextStyle.annonceDesc(
                                                    "Vous",
                                                    SizeFont.para.size,
                                                    1)
                                                : ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxWidth: 150),
                                                    child: MyTextStyle
                                                        .annonceDesc(
                                                            displayNameFor(
                                                                ref,
                                                                user,
                                                                (u) =>
                                                                    u.pseudo ??
                                                                    ""),
                                                            SizeFont
                                                                .para.size,
                                                            2),
                                                  );
                                          } else {
                                            return Container();
                                          }
                                        }),
                                  ],
                                ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyTextStyle.lotName(widget.post.title,
                                      Colors.black87, SizeFont.h3.size),
                                  ExpandableDescription(
                                    text: widget.post.description,
                                    style: GoogleFonts.roboto(
                                      fontSize: SizeFont.para.size,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: MyTextStyle.commentDate(
                                            widget.post.creationDate),
                                      ),
                                      Flexible(
                                        child: MyTextStyle.lotDesc(
                                            widget.post.statut!,
                                            SizeFont.para.size),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.canModify)
                  Container(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              if (widget.post.type == "communication") {
                                await Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) =>
                                            ModifyAskingNeighborsForm(
                                              uid: widget.uid,
                                              residence: widget.residenceId,
                                              post: widget.post,
                                            )));
                              }
                              if (!context.mounted) return;

                              if (widget.post.type == "sinistres" ||
                                  widget.post.type == "incivilites") {
                                await Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => ModifyPostForm(
                                              uid: widget.uid,
                                              residence: widget.residenceId,
                                              post: widget.post,
                                            )));
                              }
                              if (!context.mounted) return;
                              if (widget.post.type == "annonces") {
                                await Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) =>
                                            ModifyAnnonceForm(
                                              uid: widget.uid,
                                              residence: widget.residenceId,
                                              post: widget.post,
                                            )));
                              }
                              // Rafraîchit la liste au retour du
                              // formulaire, sinon la modification
                              // n'apparaît pas tant que l'écran
                              // n'est pas rechargé.
                              if (widget.updatePostsList != null) {
                                widget.updatePostsList!();
                              }
                            },
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                            )),
                        IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              showAlertDialog(context, widget.post.title);
                            },
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateUrl(String updatedUrl) {
    url = updatedUrl;
  }

  showAlertDialog(BuildContext context, String title) async {
    Widget cancelButton = TextButton(
      child: MyTextStyle.lotName("Annuler ", Colors.black87, SizeFont.h3.size),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child:
          MyTextStyle.lotName("Supprimer ", Colors.black87, SizeFont.h3.size),
      onPressed: () async {
        if (widget.updatePostsList != null) {
          _onDeletePost();
        }
      },
    );

    AlertDialog alert = AlertDialog(
      title: MyTextStyle.lotName(
          "Confirmation ", Colors.black87, SizeFont.h1.size),
      content: MyTextStyle.annonceDesc(
          "Etes-vous sûr de vouloir supprimer $title", SizeFont.h3.size, 3),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _onDeletePost() async {
    await dbService
        .removePost(widget.residenceId, widget.post.id)
        .then((result) => result.when(
            success: (_) {}, failure: (error) => throw error));
    await _storageServices.removeFileFromUrl(widget.post.pathImage!);
    for (final thumbnail in widget.post.thumbnails ?? []) {
      await _storageServices.removeFileFromUrl(thumbnail);
    }
    // await _databaseServices.getAllPostsToModify(widget.residenceId);
    widget.updatePostsList!();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
