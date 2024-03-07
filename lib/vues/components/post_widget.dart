import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/signalement_count_controller.dart';
import 'package:connect_kasa/vues/components/like_button_post.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/components/share_button.dart';
import 'package:connect_kasa/vues/components/signalement_tile.dart';
import 'package:connect_kasa/vues/pages_vues/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../../models/pages_models/post.dart';
import 'comment_button.dart';

class PostWidget extends StatefulWidget {
  late Post post;
  final String uid;
  final String residence;

  PostWidget(
    this.post,
    this.residence,
    this.uid,
  );
  @override
  State<StatefulWidget> createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  late Future<List<Post>> _signalementFuture;
  late Future<Post?> _getPostFuture;
  DataBasesServices dbService = DataBasesServices();
  int postCount = 0;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    //likeCount = widget.post.like.length;
    _signalementFuture = dbService.getSignalements(widget.residence,
        widget.post.id); // Initialisez post à partir des propriétés du widget
    _loadSignalements();

    //print("_likeCountdans postview = $likeCount");
  }

  void _loadSignalements() async {
    final signalements =
        await dbService.getSignalements(widget.residence, widget.post.id);
    setState(() {
      postCount = signalements.length;
    });
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
                  postCount = signalements.length;
                  return Column(
                    children: [
                      Container(
                        height: width, // Définir une hauteur fixe ou contrainte
                        child: FlutterCarousel(
                          options: CarouselOptions(
                            viewportFraction: 1.0,
                            pageSnapping: true,
                            showIndicator: true,
                            floatingIndicator: true,
                            slideIndicator: CircularSlideIndicator(
                              indicatorRadius: 5,
                              itemSpacing: 11.0,
                              indicatorBackgroundColor: Colors.black12,
                              currentIndicatorColor: colorStatut,
                            ),
                          ),
                          items: signalements.map((post) {
                            return InkWell(
                              onTap: () {
                                _getPostFuture = dbService.getUpdatePost(
                                    widget.residence, widget.post.id);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FutureBuilder<Post?>(
                                      future: _getPostFuture,
                                      builder: (BuildContext context,
                                          AsyncSnapshot<Post?> snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        } else {
                                          final postUpdated = snapshot.data;
                                          if (postUpdated != null) {
                                            print(
                                                "TEST / ${postUpdated.like.length}");
                                            return PostView(postUpdated,
                                                widget.residence, widget.uid);
                                          } else {
                                            return Text('No data available');
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: SignalementTile(
                                post,
                                width,
                                postCount,
                                (count) {
                                  postCount = count;
                                },
                                widget.residence,
                                widget.uid,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SignalementsCountController(
                          post: widget.post, postCount: postCount),
                    ],
                  );
                }
              },
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
                      colorIcon: colorStatut,
                      //likeCount: _likeCount(likeCount),
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
                        colorIcon: colorStatut),
                  ),
                  Container(
                      child: ShareButton(
                    post: widget.post,
                    colorIcon: colorStatut,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
