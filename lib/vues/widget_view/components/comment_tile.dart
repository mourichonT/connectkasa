// ignore_for_file: must_be_immutable

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/comment_providers.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/profil_page/show_profil_page.dart';
import 'package:konodal/vues/widget_view/components/like_button_comment.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:konodal/models/pages_models/comment.dart';
import 'package:konodal/core/utils/app_logger.dart';

class CommentTile extends ConsumerStatefulWidget {
  final Function(bool) onReply;
  final Function(String) getCommentId;
  final Function(TextEditingController) getUsertoreply;
  late Comment comment;
  final String residence;
  final String postId;
  final String uid;
  FocusNode focusNode;
  bool isReply = false;
  final TextEditingController textEditingController;
  final Function(String?) getInitialComment;

  CommentTile(
    this.residence,
    this.comment,
    this.uid,
    this.postId,
    this.focusNode,
    this.textEditingController, {
    super.key,
    this.isReply = false,
    required this.onReply,
    required this.getCommentId,
    required this.getUsertoreply,
    required this.getInitialComment,
  });

  @override
  ConsumerState<CommentTile> createState() => CommentTileState();
}

class CommentTileState extends ConsumerState<CommentTile> {
  TextEditingController _textEditingController = TextEditingController();
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  late Comment comment;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    comment = widget.comment;
  }

  @override
  void didUpdateWidget(covariant CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sans ça, une nouvelle réponse ajoutée à ce commentaire (SectionComment
    // refetch et reconstruit la liste) n'apparaissait jamais : ListView.builder
    // réutilise ce State à la même position (pas de clé), et `comment` restait
    // figé sur la valeur d'initState, ignorant le widget.comment mis à jour.
    comment = widget.comment;
  }

  @override
  Widget build(BuildContext context) {
    //Color colorStatut = Theme.of(context).primaryColor;
    // Une réponse n'a jamais de réponses imbriquées (cf. addComment/
    // _getCommentRef) - inutile d'ouvrir un stream de plus pour ces tiles.
    final replies = widget.isReply
        ? const <Comment>[]
        : ref
            .watch(repliesStreamProvider((
              residenceId: widget.residence,
              postId: widget.postId,
              commentId: comment.id,
            )))
            .valueOrNull ??
            const <Comment>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentTile(comment),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: 25.0,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                return CommentTile(
                  widget.residence,
                  replies[index],
                  widget.uid,
                  widget.postId,
                  widget.focusNode,
                  widget.textEditingController,
                  key: ValueKey(replies[index].id),
                  isReply: true,
                  onReply: widget.onReply,
                  getCommentId: widget.getCommentId,
                  getUsertoreply: widget.getUsertoreply,
                  getInitialComment: widget.getInitialComment,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAuthorName() {
    final userAsync = ref.watch(userByIdProvider(comment.user));
    final user = userAsync.valueOrNull;
    if (user != null) {
      return MyTextStyle.lotName(
          user.pseudo ?? "", Colors.black87, SizeFont.h3.size);
    } else {
      return MyTextStyle.lotName(
          "Utilisateur inconnu", Colors.black87, SizeFont.h3.size);
    }
  }

  Widget _buildCommentTile(Comment comment) {
    Color colorStatut = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 10, bottom: 5, left: 5, right: 15),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ShowProfilPage(
                              uid: comment.user,
                              currentUid: widget.uid,
                              refLot: widget.residence)),
                    );
                  },
                  child: profilTile(
                    comment.user,
                    22,
                    19,
                    22,
                    false,
                    Colors.white,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAuthorName(),
                      const SizedBox(width: 10),
                      Container(
                        child: MyTextStyle.commentDate(comment.timestamp),
                      ),
                    ],
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.50,
                      child: MyTextStyle.commentTextFormat(comment.comment)),
                  Row(
                    children: [
                      TextButton(
                        child: MyTextStyle.lotName(
                            "Répondre", Colors.black54, SizeFont.h3.size),
                        onPressed: () {
                          String initComment = "";

                          if (widget.comment.originalCommment == false) {
                            initComment = comment.initialComment!;
                            widget.isReply = true;
                            _replyToComment(
                                comment, widget.isReply, initComment);
                          } else {
                            widget.isReply = true;
                            initComment = widget.comment.id;
                            _replyToComment(comment, widget.isReply,
                                initComment); // initComment
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          LikeButtonComment(
            residence: widget.residence,
            uid: widget.uid,
            comment: comment,
            postId: widget.postId,
            color: colorStatut,
          ),
        ],
      ),
    );
  }

  void _replyToComment(
      Comment currentComment, bool isReply, String? initComment) async {
    final user =
        await ref.read(userByIdProvider(currentComment.user).future);
    if (user != null) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(widget.focusNode);
      widget.getUsertoreply(_textEditingController);
      widget.onReply(isReply);
      widget.getCommentId(currentComment.id);
      widget.getInitialComment(initComment);

      String replyText = "@${user.pseudo} ";
      _textEditingController.text = replyText;

      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textEditingController.text.length),
      );
      widget.getUsertoreply(_textEditingController);
    } else {
      appLog("Utilisateur non trouvé");
    }
  }
}
