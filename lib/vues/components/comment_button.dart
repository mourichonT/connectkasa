import 'package:connect_kasa/controllers/services/databases_services.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/vues/components/section_comment.dart';
import 'package:flutter/material.dart';
import '../../controllers/features/my_texts_styles.dart';
import '../../models/pages_models/post.dart';

class CommentButton extends StatefulWidget {
  final Post post;
  final String residenceSelected;
  final String uid;

  CommentButton({
    required this.post,
    required this.residenceSelected,
    required this.uid,
  });

  @override
  State<StatefulWidget> createState() => CommentButtonState();
}

class CommentButtonState extends State<CommentButton> {
  int? commentCount = 0;
  final DataBasesServices _databaseServices = DataBasesServices();
  late Post post;
  late String idPost;
  late Future<List<Comment>> comment;

  @override
  void initState() {
    super.initState();
    // Récupérer la future de commentaires
    comment =
        _databaseServices.getComments(widget.residenceSelected, widget.post.id);
    post = widget.post;
    idPost =
        widget.post.id; // Initialisez post à partir des propriétés du widget

    // Utiliser 'await' pour attendre que la future se résolve
    comment.then((commentList) {
      setState(() {
        // Assigner la longueur de la liste de commentaires à commentCount
        commentCount = commentList.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print("commentCount = $commentCount");
    return Row(
      children: [
        IconButton(
          icon: Icon(
            (commentCount! > 0)
                ? Icons.comment
                : Icons.messenger_outline_outlined,
            color: (commentCount! > 0) ? Theme.of(context).primaryColor : null,
            size: 20,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              isDismissible: true,
              builder: (BuildContext context) {
                return SingleChildScrollView(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            padding: EdgeInsets.only(bottom: 0),
                            child: MyTextStyle.lotName(
                                'Commentaires', Colors.black)),
                        Divider(),
                        Container(
                            padding: EdgeInsets.all(16),
                            child: SectionComment(
                              comment: comment,
                              residenceSelected: widget.residenceSelected,
                              postSelected: idPost,
                              uid: widget.uid,
                            )),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        MyTextStyle.iconText(post.setComments(commentCount))
      ],
    );
  }
}
