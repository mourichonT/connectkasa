import 'dart:async';

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/pages_vues/post_page/sinistre_tile.dart';
import 'package:flutter/material.dart';
import 'package:konodal/core/utils/app_logger.dart';

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
  // Stream plutôt qu'un Future chargé une seule fois à initState : un
  // nouveau signalement déclaré pendant que cette tuile est déjà affichée
  // n'apparaissait jamais sans quitter/revenir sur l'écran (même bug que
  // celui déjà corrigé sur PostWidget/Homeview, cf. watchSignalementsList).
  late final Stream<List<Post>> _signalementStream;

  @override
  void initState() {
    super.initState();
    _signalementStream = FirestorePostRepository()
        .watchSignalementsList(widget.residenceId, widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: _signalementStream,
      builder: (context, snapshot) {
        final signalements = snapshot.data ?? [];
        final postCount = signalements.length;
        return Column(
          children: [
            SinistreTile(widget.post, widget.residenceId, widget.uid,
                widget.canModify, widget.colorStatut, widget.updatePostsList),
            if (showSignalement && postCount != 0)
              Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: ListView.builder(
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
                          appLog(showSignalement);
                        },
                        child: !showSignalement
                            ? Row(
                                children: [
                                  MyTextStyle.postDesc(
                                      "Voir plus ($postCount)",
                                      SizeFont.para.size,
                                      Colors.black54),
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
        );
      },
    );
  }
}
