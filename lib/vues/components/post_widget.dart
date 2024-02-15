import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/vues/components/like_button.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/components/share_button.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/post.dart';
import 'comment_button.dart';

class PostWidget extends StatefulWidget {
  late Post post;

  PostWidget(this.post);
  @override
  State<StatefulWidget> createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  DataBasesServices dbService = DataBasesServices();
  late Post post;

  @override
  void initState() {
    super.initState();
    post = widget.post; // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    Color colorStatut = Theme.of(context).primaryColor;
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(color: Colors.grey, blurRadius: 8, offset: Offset(0, 1))
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
                        MyTextStyle.lotName(post!.type),
                        SizedBox(
                          width: 15,
                        ),
                        Container(
                            height: 20,
                            width: 120,
                            child: MyTextStyle.postDate(post!.timeStamp)),
                        Spacer(),
                        Container(
                            height: 20,
                            width: 70,
                            child: MyTextStyle.statuColor(
                                post.statu!, colorStatut)),
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
                          post.pathImage ?? "pas d'image",
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
                              MyTextStyle.lotName(post!.title),
                              SizedBox(
                                height: 15,
                              ),
                              MyTextStyle.lotDesc(post!.description),
                              SizedBox(
                                height: 15,
                              ),
                            ])),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Spacer(),
                          (post!.signalement > 0)
                              ? Icon(
                                  Icons.notifications,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.notifications_none,
                                  size: 20,
                                ),
                          MyTextStyle.iconText(post!.setSignalement()),
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
                    Container(child: LikeButton(post: post)),
                    Container(
                        child: CommentButton(
                      post: post,
                    )),
                    Container(child: ShareButton(post: post)),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
