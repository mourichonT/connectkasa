// ignore_for_file: library_private_types_in_public_api, must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
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
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _postCount = widget.postCount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Spacer(),
          (_postCount > 1)
              ? Icon(Icons.notifications,
                  color: Theme.of(context).primaryColor, size: 20)
              : const Icon(Icons.notifications_none, size: 20),
          const SizedBox(
            width: 10,
          ),
          MyTextStyle.iconText(widget.post.setSignalement(_postCount)),
        ],
      ),
    );
  }
}
