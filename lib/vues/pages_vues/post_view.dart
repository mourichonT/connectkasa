import 'package:connect_kasa/controllers/features/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/comment_button.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:connect_kasa/vues/components/share_button.dart';
import 'package:flutter/material.dart';

class PostView extends StatefulWidget {
  final Post post;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesServices _databaseServices = DataBasesServices();
  final String residence;
  final String uid;

  PostView(
    this.post,
    this.residence,
    this.uid,
  );

  @override
  State<StatefulWidget> createState() => PostViewState();
}

class PostViewState extends State<PostView> {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    //final DataBasesServices _databaseServices = DataBasesServices();
    late Future<User?> userPost =
        widget._databaseServices.getUserById(widget.post.user);
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Image.network(
            widget.post.pathImage ?? "pas d'image",
            fit: BoxFit.cover,
            width: width,
            height: height,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(color: Color.fromARGB(80, 0, 0, 0)),
            height: height / 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () async {
                      Post? updatedLikeCount = await widget._databaseServices
                          .getUpdatePost(widget.residence, widget.post.id);
                      print("je test le iconButton");
                      Navigator.pop(
                        context,
                      );
                      setState(() {
                        widget.post.like.length = updatedLikeCount!.like.length;
                      });
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(color: Color.fromARGB(80, 0, 0, 0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.hideUser == true)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: 10, bottom: 10, left: 10, right: 10),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: FutureBuilder<User?>(
                              future: userPost,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
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
                                          .getInitiales(17, userPost, 17);
                                    }
                                  } else {
                                    return widget.formatProfilPic
                                        .getInitiales(16, userPost, 3);
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
                              return CircularProgressIndicator();
                            } else {
                              if (snapshot.hasData && snapshot.data != null) {
                                var user = snapshot.data!;
                                return MyTextStyle.lotName(
                                    "${user.pseudo}", Colors.white);
                              } else {
                                return Text('Utilisateur inconnue',
                                    style: TextStyle(color: Colors.white));
                              }
                            }
                          },
                        ),
                      ]),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: MyTextStyle.postDesc(
                      widget.post.description, 16, Colors.white),
                ),
                Spacer(),
                Divider(),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        child: LikeButtonPost(
                          post: widget.post,
                          residence: widget.residence,
                          uid: widget.uid,
                          colorIcon: Colors.white,
                          colorText: Colors.white,
                          // likeCount: _likeCount(widget.likeCount),
                          // onUpdateLikeCount: (newLikeCount) {
                          //   setState(() {
                          //     likeCount = newLikeCount;
                          //   });
                          // },
                        ),
                      ),
                      Container(
                        child: CommentButton(
                          post: widget.post,
                          residenceSelected: widget.residence,
                          uid: widget.uid,
                          colorIcon: Colors.white,
                          colorText: Colors.white,
                        ),
                      ),
                      Container(
                          child: ShareButton(
                        post: widget.post,
                        colorIcon: Colors.white,
                        colorText: Colors.white,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
