import 'dart:async';

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/pages_vues/post_page/sinistre_tile.dart';
import 'package:flutter/material.dart';

class SinitresTileController extends StatefulWidget {
  final Post post;
  final String residenceId;
  final String uid;
  final Color colorStatut;
  final Function()? updatePostsList;
  final bool canModify;

  const SinitresTileController(
      {super.key,
      required this.post,
      required this.residenceId,
      required this.uid,
      required this.colorStatut,
      required this.updatePostsList,
      required this.canModify});

  @override
  State<StatefulWidget> createState() => SinitresTileControllerState();
}

class SinitresTileControllerState extends State<SinitresTileController> {
  bool showSignalement = false;
  late Future<List<Post>> _signalementFuture;
  DataBasesPostServices dbService = DataBasesPostServices();
  int postCount = 0;
  void _loadSignalements() {
    _signalementFuture =
        dbService.getSignalementsList(widget.residenceId, widget.post.id);
    _signalementFuture.then((signalements) {
      setState(() {
        postCount = signalements.length;
      });
    }).catchError((error) {
      // Gérer les erreurs si nécessaire
      print("Erreur lors du chargement des signalements: $error");
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Initialisez post à partir des propriétés du widget
    _loadSignalements();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SinistreTile(widget.post, widget.residenceId, widget.uid,
              widget.canModify, widget.colorStatut, widget.updatePostsList),
          if (showSignalement && postCount != 0)
            Padding(
                padding: const EdgeInsets.only(left: 25),
                child: FutureBuilder<List<Post>>(
                    future: _signalementFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        List<Post> signalements = snapshot.data!;
                        postCount = signalements.length;
                        return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            itemCount: signalements.length,
                            itemBuilder: (context, index) {
                              final post = signalements[index];

                              return SinistreTile(
                                  post,
                                  widget.residenceId,
                                  widget.uid,
                                  widget.canModify,
                                  widget.colorStatut,
                                  widget.updatePostsList);
                            });
                      }
                    })),
          if (postCount != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 0.5,
                      color: Colors.grey[400],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showSignalement = !showSignalement;
                        });
                        print(showSignalement);
                      },
                      child: !showSignalement
                          ? Row(
                              children: [
                                MyTextStyle.postDesc("Voir plus ($postCount)",
                                    SizeFont.para.size, Colors.black54),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.black54,
                                )
                              ],
                            )
                          : Row(
                              children: [
                                MyTextStyle.postDesc("Réduire",
                                    SizeFont.para.size, Colors.black54),
                                const SizedBox(
                                  width: 5,
                                ),
                                const Icon(Icons.keyboard_arrow_up,
                                    size: 18, color: Colors.black54)
                              ],
                            ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 0.5,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
