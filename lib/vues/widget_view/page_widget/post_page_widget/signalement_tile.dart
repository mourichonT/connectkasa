import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/pages_vues/profil_page/show_profil_page.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
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
                              .withValues(alpha: 0.5), // Transparent en haut
                          Colors.black12.withValues(
                              alpha: 0.2), // Semi-transparent au milieu
                          Colors.black12
                              .withValues(alpha: 0.0), // Opaque en bas
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ShowProfilPage(
                                    uid: post.user,
                                    currentUid: uid,
                                    refLot: residence)),
                          );
                        },
                        child: profilTile(post.user, 22, 19, 22, true,
                            Colors.white, SizeFont.h2.size),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
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
                post.locationElement == ""
                    ? Container()
                    : Row(
                        children: [
                          MyTextStyle.lotName("Localisation : ", Colors.black54,
                              SizeFont.h3.size),
                          MyTextStyle.lotName(
                              "${post.locationElement} ${post.locationFloor} ",
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
                //const SizedBox(height: 10),

                //SignalementsCountController(post: post, postCount: postCount),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
