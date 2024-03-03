import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import '../../models/pages_models/post.dart';

class LikeButtonComment extends StatefulWidget {
  final Comment comment;
  final String residence;
  final String uid;
  final String postId;
  final Color color;

  LikeButtonComment(
      {required this.comment,
      required this.postId,
      required this.residence,
      required this.uid,
      required this.color});

  @override
  _LikeButtonPostState createState() => _LikeButtonPostState();
}

class _LikeButtonPostState extends State<LikeButtonComment> {
  bool alreadyLiked = false;
  int likeCount = 0;
  @override
  void initState() {
    super.initState();
    alreadyLiked = widget.comment.like.contains(widget.uid);
    likeCount = widget.comment.like.length;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            alreadyLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: alreadyLiked ? widget.color : null,
            size: 20,
          ),
          onPressed: () async {
            //Appeler la méthode pour mettre à jour les likes dans la base de données
            if (!alreadyLiked) {
              await DataBasesServices().updateCommentLikes(
                widget.residence,
                widget.postId,
                widget.comment.id,
                widget.uid,
              );
              setState(() {
                alreadyLiked = true;
                likeCount++; // Incrémentez likeCount après l'ajout de like
              });
            } else {
              await DataBasesServices().removeCommentLike(
                widget.residence,
                widget.postId,
                widget.comment.id,
                widget.uid,
              );

              setState(() {
                alreadyLiked = false;
                likeCount--; // Décrémentez likeCount après la suppression de like
              });
            }
          },
        ),
        MyTextStyle.iconText(widget.comment.setLike(likeCount)),
      ],
    );
  }
}
