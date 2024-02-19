import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/components/share_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/post.dart';
import 'comment_button.dart';

class PostWidget extends StatefulWidget {
  late Post post;
  final String uid;
  final String residence;

  PostWidget(this.post, this.residence, this.uid);
  @override
  State<StatefulWidget> createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  DataBasesServices dbService = DataBasesServices();

  @override
  void initState() {
    super.initState();
    widget.post =
        widget.post; // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    Color colorStatut = Theme.of(context).primaryColor;
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(boxShadow: [
        BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
      ]),
      //color: Colors.white,
      child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ajoutez cette ligne
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 1, left: 10, right: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Centrer les éléments horizontalement
                      crossAxisAlignment: CrossAxisAlignment
                          .baseline, // Centrer les éléments verticalement
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        MyTextStyle.lotName(widget.post!.type, Colors.black87),
                        SizedBox(
                          width: 15,
                        ),
                        Container(
                            height: 20,
                            width: 120,
                            child:
                                MyTextStyle.postDate(widget.post!.timeStamp)),
                        Spacer(),
                        Container(
                            height: 20,
                            width: 70,
                            child: MyTextStyle.statuColor(
                                widget.post.statu!, colorStatut)),
                      ])),
              Divider(
                height: 20,
                thickness: 0.5,
              ),
              InkWell(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: width / 2,
                        width: width * 2,
                        child: Image.network(
                          widget.post.pathImage ?? "pas d'image",
                          fit: BoxFit.fitWidth,
                        )
                        //Image.asset(post.pathImage ?? "placeholder_image_path", fit: BoxFit.fitWidth,)
                        ),
                    Container(
                        //decoration: BoxDecoration(color: Colors.blue),
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyTextStyle.lotName(
                                  widget.post!.title, Colors.black87),
                              SizedBox(
                                height: 15,
                              ),
                              MyTextStyle.lotDesc(widget.post!.description),
                              SizedBox(
                                height: 15,
                              ),
                            ])),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Spacer(),
                          (widget.post!.signalement > 0)
                              ? Icon(
                                  Icons.notifications,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.notifications_none,
                                  size: 20,
                                ),
                          MyTextStyle.iconText(widget.post!.setSignalement()),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {},
              ),
              Divider(
                thickness: 0.5,
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        child: LikeButtonPost(
                      post: widget.post,
                      residence: widget.residence,
                      uid: widget.uid,
                    )),
                    Container(
                        child: CommentButton(
                      post: widget.post,
                      residenceSelected: widget.residence,
                      uid: widget.uid,
                    )),
                    Container(child: ShareButton(post: widget.post)),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
