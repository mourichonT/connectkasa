import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';

class SignalementTile extends StatelessWidget {
  final Post post;
  final double width;
  final int postCount;
  final Function(int) postCountCallback;
  final String residence;
  final String uid;

  SignalementTile(this.post, this.width, this.postCount, this.postCountCallback,
      this.residence, this.uid,
      {super.key});

  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  late Future<User?> userPost = databasesUserServices.getUserById(post.user);
  @override
  Widget build(BuildContext context) {
    postCountCallback(postCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 250,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  post.pathImage ?? "pas d'image",
                  fit: BoxFit.cover,
                ),
              ),
              if (post.hideUser == false)
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
                          Colors.black12
                              .withOpacity(0.2), // Semi-transparent au milieu
                          Colors.black12.withOpacity(0.0), // Opaque en bas
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: ProfilTile(post.user, 22, 19, 22, true,
                          Colors.white, SizeFont.h2.size),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MyTextStyle.lotName(
                        post.title, Colors.black87, SizeFont.h2.size),
                    const Spacer(),
                    MyTextStyle.commentDate(post.timeStamp),
                  ],
                ),
                post.location_element == ""
                    ? Container()
                    : Row(
                        children: [
                          MyTextStyle.lotName("Localisation : ", Colors.black54,
                              SizeFont.h3.size),
                          MyTextStyle.lotName(
                              "${post.location_element} ${post.location_floor} ",
                              Colors.black54,
                              SizeFont.h3.size),
                        ],
                      ),
                const SizedBox(
                  height: 15,
                ),
                Flexible(
                    child: MyTextStyle.annonceDesc(
                        post.description, SizeFont.h3.size, 3)),
                // const SizedBox(
                //   height: 10,
                // ),
                //SignalementsCountController(post: post, postCount: postCount),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
