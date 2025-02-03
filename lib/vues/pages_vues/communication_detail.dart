import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/components/comment_button.dart';
import 'package:connect_kasa/vues/components/image_annonce.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:connect_kasa/vues/components/share_button.dart';
import 'package:flutter/material.dart';

class CommunicationDetails extends StatelessWidget {
  final Post post;
  final String uid;

  const CommunicationDetails(
      {super.key, required this.post, required this.uid});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: ProfilTile(post.user, 22, 19, 22, true, Colors.black87),
      ),
      body: post.pathImage != ""
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: width,
                  child: Image.network(
                    post.pathImage!,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: width,
                    child: MyTextStyle.postDesc(
                        post.description, SizeFont.h3.size, Colors.black87),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: MyTextStyle.commentDate(post.timeStamp),
                  )
                ],
              ),
            ),
      bottomSheet: _buildButtonsRow(context),
    );
  }

  Widget _buildButtonsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        LikePostButton(
          post: post,
          residence: post.refResidence,
          uid: uid,
          colorIcon: Theme.of(context).primaryColor,
          colorIconUnselected: Colors.black87,
          colorText: Colors.black87,
        ),
        CommentButton(
          post: post,
          residenceSelected: post.refResidence,
          uid: uid,
          colorIcon: Theme.of(context).primaryColor,
          colorIconUnselected: Colors.black87,
          colorText: Colors.black87,
        ),
        ShareButton(
          post: post,
          colorIcon: Colors.black87,
          colorText: Colors.black87,
        ),
      ],
    );
  }
}
