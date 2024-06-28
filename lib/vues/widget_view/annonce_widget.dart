// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/annonce_page_details.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/pages_models/post.dart';

class AnnonceWidget extends StatefulWidget {
  final Post post;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;

  AnnonceWidget(
      {super.key,
      required this.uid,
      required this.residenceSelected,
      required this.colorStatut,
      required this.scrollController,
      required this.post});
  @override
  State<StatefulWidget> createState() => AnnonceWidgetState();
}

class AnnonceWidgetState extends State<AnnonceWidget> {
  late Future<User?> userPost;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();
  late Post? updatedPost;
  DataBasesPostServices postServices = DataBasesPostServices();

  @override
  void initState() {
    super.initState();
    //post = widget.post;
    userPost = _databasesUserServices.getUserById(widget.post.user);
    // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    _databasesUserServices.getUserById(widget.post.user);
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
              Padding(
                padding: const EdgeInsets.only(
                    top: 10, bottom: 1, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    MyTextStyle.lotName(
                        getType(widget.post), Colors.black87, SizeFont.h3.size),
                    const SizedBox(width: 15),
                    const Spacer(),
                  ],
                ),
              ),
              const Divider(
                height: 20,
                thickness: 0.5,
              ),
              InkWell(
                onTap: () async {
                  updatedPost = await postServices.getUpdatePost(
                      widget.residenceSelected, widget.post.id);

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
                    Container(
                      height: 250,
                      width: width,
                      child: widget.post.pathImage != ""
                          ? Image.network(
                              widget.post.pathImage!,
                              fit: BoxFit.cover,
                            )
                          : ImageAnnounced(context, width, 250),
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
                                child: ProfilTile(widget.post.user, 30, 26, 30,
                                    false, Colors.black),
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
                                        SizedBox(
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
                                                    SizedBox(
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
