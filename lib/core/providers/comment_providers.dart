import 'package:konodal/core/providers/comment_repository_provider.dart';
import 'package:konodal/models/pages_models/comment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Commentaires de premier niveau d'un post, en temps réel (SectionComment).
final commentsStreamProvider = StreamProvider.family<List<Comment>,
    ({String residenceId, String postId})>((ref, args) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.watchComments(args.residenceId, args.postId);
});

/// Réponses d'un commentaire donné, en temps réel (CommentTile).
final repliesStreamProvider = StreamProvider.family<List<Comment>,
    ({String residenceId, String postId, String commentId})>((ref, args) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.watchReplies(args.residenceId, args.postId, args.commentId);
});

/// Nombre total de commentaires + réponses d'un post, en temps réel
/// (badge de CommentButton).
final commentCountStreamProvider = StreamProvider.family<int,
    ({String residenceId, String postId})>((ref, args) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.watchTotalCommentCount(args.residenceId, args.postId);
});
