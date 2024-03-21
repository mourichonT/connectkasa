import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import '../../models/pages_models/post.dart';

class LikePostButton extends StatefulWidget {
  final Post post;
  final String residence;
  final String uid;
  final Color colorIcon;
  final Color? colorIconUnselected;
  final Color? colorText;

  const LikePostButton(
      {super.key,
      required this.post,
      required this.residence,
      required this.uid,
      required this.colorIcon,
      this.colorIconUnselected,
      this.colorText});

  @override
  LikePostButtonState createState() => LikePostButtonState();
}

class LikePostButtonState extends State<LikePostButton> {
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
          icon: alreadyLiked
              ? Icon(Icons.thumb_up, color: widget.colorIcon, size: 20)
              : Icon(Icons.thumb_up_alt_outlined,
                  color: widget.colorIconUnselected, size: 20),
          onPressed: () async {
            //Appeler la méthode pour mettre à jour les likes dans la base de données
            if (!alreadyLiked) {
              await DataBasesPostServices().updatePostLikes(
                widget.residence,
                widget.post.id,
                widget.uid,
              );
              setState(() {
                alreadyLiked = true;
                likeCount++; // Incrémentez likeCount après l'ajout de like
              });
            } else {
              await DataBasesPostServices().removePostLike(
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
        MyTextStyle.iconText(widget.post.setLike(likeCount),
            color: widget.colorText),
      ],
    );
  }
}
