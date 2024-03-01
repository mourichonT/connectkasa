import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/components/share_button.dart';
import 'package:connect_kasa/vues/components/signalement_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

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
  late Future<List<Post>> _signalementFuture;
  DataBasesServices dbService = DataBasesServices();

  @override
  void initState() {
    super.initState();
    _signalementFuture = dbService.getSignalements(widget.residence,
        widget.post.id); // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    Color colorStatut = Theme.of(context).primaryColor;
    double width = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10, bottom: 1, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  MyTextStyle.lotName(widget.post.type, Colors.black87),
                  SizedBox(width: 15),
                  Container(
                    height: 20,
                    width: 120,
                    child: MyTextStyle.postDate(widget.post.timeStamp),
                  ),
                  Spacer(),
                  Container(
                    height: 20,
                    width: 70,
                    child:
                        MyTextStyle.statuColor(widget.post.statu!, colorStatut),
                  ),
                ],
              ),
            ),
            Divider(
              height: 20,
              thickness: 0.5,
            ),
            FutureBuilder<List<Post>>(
              future: _signalementFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<Post> signalements = snapshot.data!;
                  return Container(
                    height: width, // Définir une hauteur fixe ou contrainte
                    child: FlutterCarousel(
                      options: CarouselOptions(
                        viewportFraction: 1.0,
                        pageSnapping: true,
                        showIndicator: true,
                        floatingIndicator: true,
                        slideIndicator: CircularSlideIndicator(
                            itemSpacing: 15.0,
                            indicatorBackgroundColor: Colors.black12,
                            currentIndicatorColor: colorStatut),
                      ),
                      items: signalements.map((post) {
                        return SignalementTile(post, width);
                      }).toList(),
                    ),
                  );
                }
              },
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Spacer(),
                  (widget.post.signalement > 0)
                      ? Icon(Icons.notifications,
                          color: Theme.of(context).primaryColor, size: 20)
                      : Icon(Icons.notifications_none, size: 20),
                  MyTextStyle.iconText(widget.post.setSignalement()),
                ],
              ),
            ),
            Divider(thickness: 0.5),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    child: LikeButtonPost(
                      post: widget.post,
                      residence: widget.residence,
                      uid: widget.uid,
                    ),
                  ),
                  Container(
                    child: CommentButton(
                      post: widget.post,
                      residenceSelected: widget.residence,
                      uid: widget.uid,
                    ),
                  ),
                  Container(child: ShareButton(post: widget.post)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
