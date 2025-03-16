import 'package:connect_kasa/controllers/features/line_interaction.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/post_page/post_view.dart';
import 'package:connect_kasa/vues/widget_view/components/header_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AskingNeighborsWidget extends StatefulWidget {
  final Post post;
  final String uid;
  final String residenceSelected;
  final Color colorStatut;
  final double scrollController;
  final bool isCsMember;
  final Function updatePostsList;

  const AskingNeighborsWidget(
      {super.key,
      required this.post,
      required this.uid,
      required this.residenceSelected,
      required this.colorStatut,
      required this.scrollController,
      required this.isCsMember,
      required this.updatePostsList});

  @override
  State<StatefulWidget> createState() => AskingNeighborsState();
}

class AskingNeighborsState extends State<AskingNeighborsWidget> {
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
            CustomHeaderRow(
              post: widget.post,
              isCsMember: widget.isCsMember,
              updatePostsList: widget.updatePostsList,
            ),
            const Divider(
              height: 20,
              thickness: 0.5,
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
                                  Colors.black12
                                      .withOpacity(0.5), // Transparent en haut
                                  Colors.black12.withOpacity(
                                      0.2), // Semi-transparent au milieu
                                  Colors.black12
                                      .withOpacity(0.0), // Opaque en bas
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: ProfilTile(widget.post.user, 22, 19, 22,
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
                            : ProfilTile(widget.post.user, 22, 19, 22, true,
                                Colors.black87, SizeFont.h2.size),
                        MyTextStyle.commentDate(widget.post.timeStamp),
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
            IteractionLine(widget.post, widget.residenceSelected, widget.uid,
                widget.colorStatut)
          ],
        ),
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
