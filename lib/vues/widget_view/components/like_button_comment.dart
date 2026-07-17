import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/comment_repository_provider.dart';
import 'package:konodal/models/pages_models/comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// alreadyLiked/likeCount sont dérivés de widget.comment.like à chaque
/// build, jamais recopiés dans un state local - widget.comment vient déjà
/// de commentsStreamProvider/repliesStreamProvider (temps réel), cf.
/// LikePostButton pour le même principe côté posts.
class LikeButtonComment extends ConsumerWidget {
  final Comment comment;
  final String residence;
  final String uid;
  final String postId;
  final Color color;

  const LikeButtonComment(
      {super.key,
      required this.comment,
      required this.postId,
      required this.residence,
      required this.uid,
      required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alreadyLiked = comment.like.contains(uid);
    final likeCount = comment.like.length;

    return Row(
      children: [
        IconButton(
          icon: Icon(
            alreadyLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: alreadyLiked ? color : null,
            size: 20,
          ),
          onPressed: () async {
            final repository = ref.read(commentRepositoryProvider);
            if (!alreadyLiked) {
              await repository.updateCommentLikes(
                  residence, postId, comment.id, uid);
            } else {
              await repository.removeCommentLike(
                  residence, postId, comment.id, uid);
            }
          },
        ),
        MyTextStyle.iconText(comment.setLike(likeCount)),
      ],
    );
  }
}
