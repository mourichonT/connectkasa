import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/widget_view/components/comment_button.dart';
import 'package:connect_kasa/vues/widget_view/components/like_button_post.dart';
import 'package:connect_kasa/vues/widget_view/components/share_button.dart';
import 'package:flutter/material.dart';

Widget IteractionLine(
    Post post, String residence, String uid, Color colorStatut) {
  return Column(
    children: [
      const Divider(thickness: 0.6),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          LikePostButton(
            post: post,
            residence: residence,
            uid: uid,
            colorIcon: colorStatut,
          ),
          CommentButton(
              post: post,
              residenceSelected: residence,
              uid: uid,
              colorIcon: colorStatut),
          ShareButton(
            post: post,
            //colorIcon: colorStatut,
          ),
        ],
      ),
    ],
  );
}
