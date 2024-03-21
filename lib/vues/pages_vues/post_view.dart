// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/comment_button.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:connect_kasa/vues/components/share_button.dart';

class PostView extends StatefulWidget {
  late Post postOrigin;
  late Post postSelected;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();
  final DataBasesPostServices _databasesPostServices = DataBasesPostServices();
  final String residence;
  final String uid;

  PostView(this.postOrigin, this.postSelected, this.residence, this.uid,
      {super.key});

  @override
  State<StatefulWidget> createState() => PostViewState();

  Widget _buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        LikePostButton(
          post: postOrigin,
          residence: residence,
          uid: uid,
          colorIcon: Colors.white,
          colorIconUnselected: Colors.white,
          colorText: Colors.white,
        ),
        CommentButton(
          post: postOrigin,
          residenceSelected: residence,
          uid: uid,
          colorIcon: Colors.white,
          colorIconUnselected: Colors.white,
          colorText: Colors.white,
        ),
        ShareButton(
          post: postOrigin,
          colorIcon: Colors.white,
          colorText: Colors.white,
        ),
      ],
    );
  }
}

class PostViewState extends State<PostView> {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    late Future<User?> userPost =
        widget._databasesUserServices.getUserById(widget.postSelected.user);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(230, 0, 0, 0),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                widget.postSelected.pathImage ?? "pas d'image",
                fit: BoxFit.fitWidth,
                width: width,
                height: height,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration:
                    const BoxDecoration(color: Color.fromARGB(80, 0, 0, 0)),
                height: height / 9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      onPressed: () async {
                        Post? updatedLikeCount =
                            await widget._databasesPostServices.getUpdatePost(
                                widget.residence, widget.postSelected.id);
                        Navigator.pop(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: MyTextStyle.lotName(
                        "${widget.postSelected.title} / ${widget.postSelected.emplacement}",
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration:
                    const BoxDecoration(color: Color.fromARGB(80, 0, 0, 0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.postSelected.hideUser == false)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 10,
                              left: 10,
                              right: 10,
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: FutureBuilder<User?>(
                                future: userPost,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      var user = snapshot.data!;
                                      if (user.profilPic != null &&
                                          user.profilPic != "") {
                                        return widget.formatProfilPic
                                            .ProfilePic(17, userPost);
                                      } else {
                                        return widget.formatProfilPic
                                            .getInitiales(34, userPost, 17);
                                      }
                                    } else {
                                      return widget.formatProfilPic
                                          .getInitiales(17, userPost, 3);
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                          FutureBuilder<User?>(
                            future: userPost,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else {
                                if (snapshot.hasData && snapshot.data != null) {
                                  var user = snapshot.data!;
                                  return MyTextStyle.lotName(
                                    user.pseudo,
                                    Colors.white,
                                  );
                                } else {
                                  return const Text(
                                    'Utilisateur inconnue',
                                    style: TextStyle(color: Colors.white),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: MyTextStyle.postDesc(
                          widget.postSelected.description,
                          16,
                          Colors.white,
                        ),
                      ),
                    ),
                    const Divider(),
                    // Utilisation de la méthode _buildButtonsRow
                    widget._buildButtonsRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
