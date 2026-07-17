import 'package:konodal/core/providers/comment_providers.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/widget_view/page_widget/section_comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/features/my_texts_styles.dart';
import '../../../models/pages_models/post.dart';

class CommentButton extends ConsumerStatefulWidget {
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
  ConsumerState<CommentButton> createState() => CommentButtonState();
}

class CommentButtonState extends ConsumerState<CommentButton> {
  @override
  Widget build(BuildContext context) {
    final commentCount = ref
            .watch(commentCountStreamProvider((
              residenceId: widget.residenceSelected,
              postId: widget.post.id,
            )))
            .valueOrNull ??
        0;

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
                        child: MyTextStyle.lotName(
                            'Commentaires', Colors.black87, SizeFont.h1.size)),
                    const Divider(),
                    SectionComment(
                      residenceSelected: widget.residenceSelected,
                      postSelected: widget.post.id,
                      uid: widget.uid,
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
          MyTextStyle.iconText(widget.post.setComments(commentCount),
              color: widget.colorText)
        ],
      ),
    );
  }
}
