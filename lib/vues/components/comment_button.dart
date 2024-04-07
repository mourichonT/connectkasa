import 'package:connect_kasa/controllers/services/databases_comment_services.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/vues/widget_view/section_comment.dart';
import 'package:flutter/material.dart';
import '../../controllers/features/my_texts_styles.dart';
import '../../models/pages_models/post.dart';

class CommentButton extends StatefulWidget {
  final Post post;
  final String residenceSelected;
  final String uid;
  final Color colorIcon;
  final Color? colorIconUnselected;
  final Color? colorText;

  const CommentButton(
      {super.key,
      required this.post,
      required this.residenceSelected,
      required this.uid,
      required this.colorIcon,
      this.colorIconUnselected,
      this.colorText});

  @override
  State<StatefulWidget> createState() => CommentButtonState();
}

class CommentButtonState extends State<CommentButton> {
  int commentCount = 0;
  final DataBasesCommentServices _databaseCommentServices =
      DataBasesCommentServices();
  late Post post;
  late String idPost;
  late Future<List<Comment>> comment;

  @override
  void initState() {
    super.initState();
    // Récupérer la future de commentaires
    comment = _databaseCommentServices.getComments(
        widget.residenceSelected, widget.post.id);
    post = widget.post;
    idPost =
        widget.post.id; // Initialisez post à partir des propriétés du widget

    // Utiliser 'await' pour attendre que la future se résolve
    comment.then((commentList) {
      setState(() {
        processComments(commentList);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          isDismissible: true,
          builder: (BuildContext context) {
            return SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        padding: const EdgeInsets.only(bottom: 0),
                        child:
                            MyTextStyle.lotName('Commentaires', Colors.black)),
                    const Divider(),
                    SectionComment(
                      comment: comment,
                      residenceSelected: widget.residenceSelected,
                      postSelected: idPost,
                      uid: widget.uid,
                      onCommentAdded: () => _onCommentAdded(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (commentCount > 0)
              ? Icon(
                  Icons.comment,
                  color: widget.colorIcon,
                  size: 20,
                )
              : Icon(
                  Icons.messenger_outline_outlined,
                  color: widget.colorIconUnselected,
                  size: 20,
                ),
          const SizedBox(
            width: 15,
          ),
          MyTextStyle.iconText(post.setComments(commentCount),
              color: widget.colorText)
        ],
      ),
    );
  }

// Callback function to be called when a comment is added
  // Callback function to be called when a comment is added
  void _onCommentAdded() {
    if (mounted) {
      setState(() {
        // Mettez à jour le nombre de commentaires
        comment = _databaseCommentServices.getComments(
            widget.residenceSelected, widget.post.id);
      });
      // Recalculer le nombre de commentaires après l'ajout d'un commentaire
      comment.then((commentList) {
        if (mounted) {
          setState(() {
            processComments(commentList);
          });
        }
      });
    }
  }

  void processComments(List<Comment> comments) async {
    int totalCount = await getTotalComment(comments, 0);
    setState(() {
      commentCount = totalCount;
    });
  }

  Future<int> getTotalComment(List<Comment> comments, int count) async {
    for (var comment in comments) {
      count++; // Compte le commentaire
      count += await getTotalComment(
          comment.replies, 0); // Compte les réponses récursivement
    }
    return count;
  }
}
