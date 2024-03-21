import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

class CommentCountWidget extends StatelessWidget {
  final int commentCount;

  const CommentCountWidget({
    super.key,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    String formatCommentCount = commentCount.toString();
    return MyTextStyle.iconText(formatCommentCount);
  }
}
