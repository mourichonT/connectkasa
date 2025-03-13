// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/line_interaction.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/signalement_count_controller.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/widget_view/header_row.dart';
import 'package:connect_kasa/vues/widget_view/signalement_tile.dart';
import 'package:connect_kasa/vues/pages_vues/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

import '../../models/pages_models/post.dart';

class PostWidget extends StatefulWidget {
  late Post post;
  final String uid;
  final String residence;
  final double scrollController;
  final bool isCsMember;

  PostWidget(this.post, this.residence, this.uid, this.scrollController,
      this.isCsMember,
      {super.key});
  @override
  State<StatefulWidget> createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> {
  late Future<List<Post>> _signalementFuture;
  late Future<Post?> _getPostFuture;
  DataBasesPostServices dbService = DataBasesPostServices();
  List<List<String>> typeList = TypeList().typeDeclaration();
  int postCount = 0;
  int likeCount = 0;
  @override
  void initState() {
    super.initState();
    //likeCount = widget.post.like.length;
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
            CustomHeaderRow(
              post: widget.post,
              colorStatut: colorStatut,
              isCsMember: widget.isCsMember,
            ),
            const Divider(
              height: 20,
              thickness: 0.5,
            ),
            FutureBuilder<List<Post>>(
              future: _signalementFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<Post> signalements = snapshot.data!;
                  postCount = signalements.length;
                  return Column(
                    children: [
                      SizedBox(
                        height: width, // Définir une hauteur fixe ou contrainte
                        child: FlutterCarousel(
                          options: FlutterCarouselOptions(
                            viewportFraction: 1.0,
                            pageSnapping: true,
                            showIndicator: true,
                            floatingIndicator: true,
                            slideIndicator: CircularSlideIndicator(
                                slideIndicatorOptions: SlideIndicatorOptions(
                                    indicatorRadius: 5,
                                    indicatorBackgroundColor: Colors.black12,
                                    currentIndicatorColor: colorStatut,
                                    itemSpacing: 13)
                                // indicatorRadius: 5,
                                // itemSpacing: 11.0,
                                // indicatorBackgroundColor: Colors.black12,
                                // currentIndicatorColor: colorStatut,
                                ),
                          ),
                          items: signalements.map((postSelected) {
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
                                          return const CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        } else {
                                          final postUpdated = snapshot.data;
                                          if (postUpdated != null) {
                                            return PopScope(
                                              onPopInvoked: (didPop) async {
                                                Post? postChanges =
                                                    await dbService
                                                        .getUpdatePost(
                                                            widget.residence,
                                                            widget.post.id);

                                                setState(() {
                                                  widget.post = postChanges!;
                                                });
                                              },
                                              child: PostView(
                                                postOrigin: postUpdated,
                                                residence: widget.residence,
                                                uid: widget.uid,
                                                scrollController:
                                                    widget.scrollController,
                                                postSelected: postSelected,
                                                returnHomePage: true,
                                              ),
                                            );
                                          } else {
                                            return const Text(
                                                'No data available');
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: SignalementTile(
                                postSelected,
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
            IteractionLine(
                widget.post, widget.residence, widget.uid, colorStatut)
          ],
        ),
      ),
    );
  }
}
