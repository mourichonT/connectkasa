import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/post_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/pages_models/post.dart';

/// alreadyLiked/likeCount sont dérivés de widget.post.like à chaque build,
/// jamais recopiés dans un state local : widget.post vient déjà d'un
/// provider temps réel (postsByResidenceProvider et consorts), donc un like
/// posé par quelqu'un d'autre pendant que ce bouton est affiché se reflète
/// automatiquement - un state local figé à l'initState (l'ancienne
/// implémentation) l'aurait ignoré, comme observé sur CommentTile avant son
/// correctif.
class LikePostButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final like = post.like ?? [];
    final alreadyLiked = like.contains(uid);
    final likeCount = like.length;

    return Row(
      children: [
        IconButton(
          icon: alreadyLiked
              ? Icon(Icons.thumb_up, color: colorIcon, size: 20)
              : Icon(Icons.thumb_up_alt_outlined,
                  color: colorIconUnselected, size: 20),
          onPressed: () async {
            final repository = ref.read(postRepositoryProvider);
            final result = alreadyLiked
                ? await repository.removePostLike(residence, post.id, uid)
                : await repository.updatePostLikes(residence, post.id, uid);
            result.when(
                success: (_) {}, failure: (error) => throw error);
          },
        ),
        MyTextStyle.iconText(post.setLike(likeCount), color: colorText),
      ],
    );
  }
}
