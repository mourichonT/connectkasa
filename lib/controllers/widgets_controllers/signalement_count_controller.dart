// ignore_for_file: library_private_types_in_public_api, must_be_immutable

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:flutter/material.dart';

class SignalementsCountController extends StatefulWidget {
  int postCount;
  late Post post;

  SignalementsCountController(
      {super.key, required this.post, required this.postCount});

  @override
  _SignalementsCountControllerState createState() =>
      _SignalementsCountControllerState();
}

class _SignalementsCountControllerState
    extends State<SignalementsCountController> {
  // Lire widget.postCount directement plutôt que le copier une fois dans
  // initState() : le parent (PostWidget) passe un postCount à jour à
  // chaque émission de son StreamBuilder de signalements, mais une copie
  // locale figée à la création de ce State ignorait silencieusement toute
  // mise à jour ultérieure (pas de didUpdateWidget).
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Spacer(),
          (widget.postCount > 1)
              ? Icon(Icons.notifications,
                  color: Theme.of(context).primaryColor, size: 20)
              : const Icon(Icons.notifications_none, size: 20),
          const SizedBox(
            width: 10,
          ),
          MyTextStyle.iconText(widget.post.setSignalement(widget.postCount)),
        ],
      ),
    );
  }
}
