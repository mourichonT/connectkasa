import 'package:connect_kasa/vues/components/like_button.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/datas/datas_posts.dart';
import 'package:connect_kasa/vues/components/section_comment.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/post.dart';
import 'comment_button.dart';

class PostWidget extends StatefulWidget {
  late Post post;

  PostWidget(this.post);
@override
  State<StatefulWidget> createState()=> PostWidgetState();

}
class PostWidgetState extends State<PostWidget>{
  late Post post;


  @override
  void initState() {
    super.initState();
    post = widget.post; // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
          blurRadius: 8 ,
          offset: Offset(0,1))]
      ),
      //color: Colors.white,
      child:Container(
        color: Colors.white,
          child :Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical:10, horizontal: 10),
            child:Row( children:[
            MyTextStyle.lotName(post!.type),
            Spacer(),
            Text(post!.date),]
          )),
          Container(
              height:width/2 ,
              width: width*2 ,
              child: Image.asset(post.pathImage ?? "placeholder_image_path", fit: BoxFit.fill,)
          ),
         Container(padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
             child : Column(
               mainAxisAlignment: MainAxisAlignment.start,
               children:[
                  MyTextStyle.lotName(post!.title),
                  MyTextStyle.lotDesc(post!.description),
                ]
              )),
          // Ajoutez d'autres détails du post selon vos besoins
        Divider(),
          Container(child:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                LikeButton(post: post),
                CommentButton(post: post,),
                (post!.comment>0)?Icon(Icons.notifications, color: Theme.of(context).primaryColor,):Icon(Icons.notifications_none),
                Text(post!.setSignalement()),

              ],
            ),
          ),

        ],
      )),
    );
  }
}