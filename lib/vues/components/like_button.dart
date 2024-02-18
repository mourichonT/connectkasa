import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/services/databases_services.dart';
import '../../models/pages_models/post.dart';

class LikeButton extends StatefulWidget {
  final Post post;
  final String residence;
  final String uid;

  LikeButton({required this.post, required this.residence, required this.uid});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool alreadyLiked = false;
  int likeCount = 0;
  @override
  void initState() {
    super.initState();
    alreadyLiked = widget.post.like.contains(widget.uid);
    likeCount = widget.post.like.length;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            alreadyLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: alreadyLiked ? Theme.of(context).primaryColor : null,
            size: 20,
          ),
          onPressed: () async {
            //Appeler la méthode pour mettre à jour les likes dans la base de données
            if (!alreadyLiked) {
              await DataBasesServices().updatePostLikes(
                widget.residence,
                widget.post.id,
                widget.uid,
              );
              setState(() {
                alreadyLiked = true;
                likeCount++; // Incrémentez likeCount après l'ajout de like
              });
            } else {
              await DataBasesServices().removePostLike(
                widget.residence,
                widget.post.id,
                widget.uid,
              );

              setState(() {
                alreadyLiked = false;
                likeCount--; // Décrémentez likeCount après la suppression de like
              });
            }
          },
        ),
        MyTextStyle.iconText(widget.post.setLike(likeCount)),
      ],
    );
  }
}
