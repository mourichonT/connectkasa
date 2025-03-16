import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../controllers/features/my_texts_styles.dart';
import '../../../models/pages_models/post.dart';

class ShareButton extends StatelessWidget {
  final Post post;
  final Color? colorIcon;
  final Color? colorText;

  const ShareButton(
      {super.key, required this.post, this.colorIcon, this.colorText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.share,
            color: colorIcon,
            size: 20,
          ),
          onPressed: () {
            Share.share(
                'Regardez ce post sur WhatsApp: ${post.title}\n${post.description}');
          },
        ),
        MyTextStyle.iconText("Partager", color: colorText),
      ],
    );
  }
}
