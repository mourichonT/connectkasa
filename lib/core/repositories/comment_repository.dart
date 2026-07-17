import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/comment.dart';

/// Remplace DataBasesCommentServices (Phase 2 du chantier architecture).
abstract interface class ICommentRepository {
  /// Commentaires de premier niveau d'un post, en temps réel (sans les
  /// réponses - cf. watchReplies, chargées séparément par CommentTile).
  Stream<List<Comment>> watchComments(String docRes, String postId);

  /// Réponses d'un commentaire donné, en temps réel.
  Stream<List<Comment>> watchReplies(
      String docRes, String postId, String commentId);

  /// Nombre total de commentaires + réponses d'un post, en temps réel
  /// (CommentButton). Se réévalue à chaque changement de la collection
  /// "comments" (comptage des réponses recalculé via une requête
  /// d'agrégation à ce moment-là).
  Stream<int> watchTotalCommentCount(String docRes, String postId);

  Future<Result<void>> updateCommentLikes(String residenceId, String postId,
      String commentId, String userId);

  Future<Result<void>> removeCommentLike(String residenceId, String postId,
      String commentId, String userId);

  Future<Result<List<Comment>>> addComment(
      String docRes, String postId, Comment newComment,
      {String? commentId, String? initialComment});
}
