import 'package:connect_kasa/controllers/services/databases_services.dart';
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
  final DataBasesServices _databaseServices = DataBasesServices();
  late Post post;
  late String idPost;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    idPost =
        widget.post.id; // Initialisez post à partir des propriétés du widget
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            (post.comment > 0)
                ? Icons.comment
                : Icons.messenger_outline_outlined,
            color: (post.comment > 0) ? Theme.of(context).primaryColor : null,
            size: 20,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              //isScrollControlled: true,
              isDismissible: true,
              builder: (BuildContext context) {
                return SectionComment(
                  residenceSelected: widget.residenceSelected,
                  postSelected: idPost,
                  uid: widget.uid,
                );
              },
            );
          },
        ),
        MyTextStyle.iconText(post.setComments())
      ],
    );
  }
}
