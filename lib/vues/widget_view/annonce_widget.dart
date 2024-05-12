// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
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
                    MyTextStyle.lotName(getType(widget.post), Colors.black87),
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
                    widget.post.pathImage != ""
                        ? Image.network(
                            widget.post.pathImage!,
                            fit: BoxFit.cover,
                          )
                        : ImageAnnounced(context, width, 250),
                    Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.start, // Ajustez cette ligne
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 5, bottom: 5, left: 5, right: 20),
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: FutureBuilder<User?>(
                                    future: userPost, // Future<User?> ici
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        // Afficher un indicateur de chargement si le futur est en cours de chargement
                                        return const CircularProgressIndicator();
                                      } else {
                                        // Si le futur est résolu, vous pouvez accéder aux propriétés de l'objet User
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          var user = snapshot.data!;
                                          if (user.profilPic != null &&
                                              user.profilPic != "") {
                                            // Retourner le widget avec l'image de profil si disponible
                                            return formatProfilPic.ProfilePic(
                                                35, userPost);
                                          } else {
                                            // Sinon, retourner les initiales
                                            return formatProfilPic.getInitiales(
                                                65, userPost, 37);
                                          }
                                        } else {
                                          // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
                                          return formatProfilPic.getInitiales(
                                              65,
                                              userPost,
                                              3); // ou tout autre widget par défaut
                                        }
                                      }
                                    },
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
                                              Colors.black87),
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
                                                      13)),
                                              const Spacer(),
                                              SizedBox(
                                                  height: 20,
                                                  width: 120,
                                                  child: MyTextStyle.postDate(
                                                      widget.post.timeStamp))
                                            ])),
                                        Flexible(
                                          child: MyTextStyle.annonceDesc(
                                              widget.post.description, 14, 3),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 15),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Row(
                                                    children: [
                                                      MyTextStyle.lotDesc(
                                                        "Prix:",
                                                        14,
                                                        FontWeight.w900,
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      MyTextStyle.lotDesc(
                                                        widget.post.setPrice(
                                                            widget.post.price),
                                                        14,
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
                                                                      widget
                                                                          .uid,
                                                                  idUserTo: widget
                                                                      .post
                                                                      .user)));
                                                    },
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    icon: Icons.mail,
                                                    text: "Contacter",
                                                    horizontal: 10,
                                                    vertical: 2,
                                                  ),
                                                ],
                                              ),
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
