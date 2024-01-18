import 'package:flutter/material.dart';
import '../../models/pages_models/post.dart';

class LikeButton extends StatefulWidget {
  final Post post;

  LikeButton({required this.post});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Row (
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
              color: isLiked ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () {
              setState(() {
                if (isLiked) {
                  widget.post.like -= 1;
                } else {
                  widget.post.like += 1;
                }
                isLiked = !isLiked;
              });
            },
        ),
          Text(widget.post.setLike()),
        ]
        );
  }
}