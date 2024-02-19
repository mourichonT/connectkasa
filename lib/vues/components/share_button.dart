import 'package:flutter/material.dart';
import 'package:share/share.dart';
import '../../controllers/features/my_texts_styles.dart';
import '../../models/pages_models/post.dart';

class ShareButton extends StatelessWidget {
  final Post post;

  ShareButton({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.share,
            size: 20,
          ),
          onPressed: () {
            Share.share(
                'Regardez ce post sur WhatsApp: ${post.title}\n${post.description}');
          },
        ),
        MyTextStyle.iconText("Partager"),
      ],
    );
  }
}
