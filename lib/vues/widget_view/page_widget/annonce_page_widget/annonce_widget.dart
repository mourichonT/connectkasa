// ignore_for_file: must_be_immutable

import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/pages_vues/profil_page/show_profil_page.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/vues/pages_vues/annonces_page/annonce_page_details.dart';
import 'package:konodal/vues/pages_vues/chat_page/chat_page.dart';
import 'package:konodal/vues/widget_view/components/header_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../models/pages_models/post.dart';

class AnnonceWidget extends StatefulWidget {
  final Post post;
  final Lot lot;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  const AnnonceWidget({
    super.key,
    required this.uid,
    required this.residenceSelected,
    required this.colorStatut,
    required this.scrollController,
    required this.post,
    required this.lot,
    required this.isCsMember,
    required this.updatePostsList,
  });
  @override
  State<StatefulWidget> createState() => AnnonceWidgetState();
}

class AnnonceWidgetState extends State<AnnonceWidget> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  late Post? updatedPost;
  IPostRepository postServices = FirestorePostRepository();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(boxShadow: [
        BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
      ]),
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
                isCsMember: widget.isCsMember,
                updatePostsList: widget.updatePostsList,
              ),
              const Divider(
                height: 20,
                thickness: 0.5,
              ),
              InkWell(
                onTap: () async {
                  updatedPost = await postServices
                      .getUpdatePost(widget.residenceSelected, widget.post.id)
                      .then((result) => result.when(
                          success: (v) => v, failure: (_) => null));

                  if (!context.mounted) return;
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => AnnoncePageDetails(
                      returnHomePage: true,
                      post: updatedPost!,
                      uid: widget.uid,
                      residence: widget.residenceSelected,
                      colorStatut: widget.colorStatut,
                      scrollController: widget.scrollController,
                    ),
                  ));
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      width: width,
                      child: widget.post.pathImage != ""
                          ? Image.network(
                              widget.post.pathImage!,
                              fit: BoxFit.cover,
                            )
                          : imageAnnounced(context, width, 250),
                    ),
                    Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.start, // Ajustez cette ligne
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ShowProfilPage(
                                              uid: widget.post.user,
                                              currentUid: widget.uid,
                                              refLot:
                                                  widget.residenceSelected)),
                                    );
                                  },
                                  child: profilTile(
                                    widget.post.user,
                                    30,
                                    26,
                                    30,
                                    false,
                                    Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          child: MyTextStyle.lotName(
                                              widget.post.title,
                                              Colors.black87,
                                              SizeFont.h2.size),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Row(children: [
                                              SizedBox(
                                                  height: 20,
                                                  width: 120,
                                                  child: MyTextStyle.lotDesc(
                                                      widget.post.subtype ??
                                                          'n/a',
                                                      SizeFont.h3.size)),
                                              const Spacer(),
                                              MyTextStyle.commentDate(
                                                  widget.post.timeStamp)
                                            ])),
                                        Flexible(
                                          child: MyTextStyle.annonceDesc(
                                              widget.post.description,
                                              SizeFont.h3.size,
                                              3),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Row(
                                                  children: [
                                                    MyTextStyle.lotDesc(
                                                      "Prix:",
                                                      SizeFont.h3.size,
                                                      FontStyle.italic,
                                                      FontWeight.w900,
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    MyTextStyle.lotDesc(
                                                      widget.post.setPrice(
                                                          widget.post.price),
                                                      SizeFont.h3.size,
                                                      FontStyle.italic,
                                                      FontWeight.w900,
                                                    ),
                                                  ],
                                                ),
                                                ButtonAdd(
                                                  function: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) => ChatPage(
                                                                message:
                                                                    "Je vous contact au sujet de votre annonce \"${widget.post.title}\", est-ce toujours possible?",
                                                                residence: widget
                                                                    .residenceSelected,
                                                                idUserFrom:
                                                                    widget.uid,
                                                                idUserTo: widget
                                                                    .post
                                                                    .user)));
                                                  },
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  icon: Icons.mail,
                                                  text: "Contacter",
                                                  horizontal: 10,
                                                  vertical: 5,
                                                  size: SizeFont.h3.size,
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    )),
                              )
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ]),
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
