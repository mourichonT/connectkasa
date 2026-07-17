// ignore_for_file: must_be_immutable

import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/profil_page/show_profil_page.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/controllers/pages_controllers/my_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/comment_button.dart';
import 'package:konodal/vues/widget_view/components/image_annonce.dart';
import 'package:konodal/vues/widget_view/components/like_button_post.dart';
import 'package:konodal/vues/widget_view/components/network_video_player.dart';
import 'package:konodal/vues/widget_view/components/share_button.dart';

class PostView extends StatefulWidget {
  late Post postOrigin;
  late Post? postSelected;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final String residence;
  final String uid;
  final double? scrollController;
  final bool returnHomePage;

  PostView(
      {super.key,
      required this.postOrigin,
      required this.residence,
      required this.uid,
      this.scrollController,
      required this.postSelected,
      required this.returnHomePage});

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(230, 0, 0, 0),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              // "?? ..." ne couvre que le cas null : pathImage vide (post
              // sans photo) passait quand même "" à Image.network, qui lève
              // une ArgumentError non rattrapée ("No host specified in URI").
              child: widget.postSelected!.isVideo
                  ? NetworkVideoPlayer(
                      url: widget.postSelected!.pathImage ?? "",
                    )
                  : ((widget.postSelected!.pathImage ?? "").isNotEmpty
                      ? Image.network(
                          widget.postSelected!.pathImage!,
                          fit: BoxFit.fitWidth,
                          width: width,
                          height: height,
                        )
                      : imageAnnounced(context, width, height)),
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
                        widget.returnHomePage
                            ? Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyNavBar(
                                    uid: widget.uid,
                                    scrollController: widget.scrollController,
                                  ),
                                ),
                              )
                            : Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: MyTextStyle.lotName(
                          "${widget.postSelected!.title} / ${widget.postSelected!.locationElement}",
                          Colors.white,
                          SizeFont.h2.size),
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
                    if (widget.postSelected!.hideUser == false)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ShowProfilPage(
                                      uid: widget.postSelected!.user,
                                      currentUid: widget.uid,
                                      refLot: widget.residence)),
                            );
                          },
                          child: profilTile(widget.postSelected!.user, 22, 19,
                              22, true, Colors.white, SizeFont.h2.size),
                        ),
                      ),

                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: MyTextStyle.postDesc(
                          widget.postSelected!.description,
                          SizeFont.h2.size,
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
