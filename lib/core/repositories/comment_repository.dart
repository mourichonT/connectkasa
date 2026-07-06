import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';

/// Remplace DataBasesCommentServices (Phase 2 du chantier architecture).
abstract interface class ICommentRepository {
  Future<Result<List<Comment>>> getComments(String docRes, String postId);

  Future<Result<void>> updateCommentLikes(String residenceId, String postId,
      String commentId, String userId);

  Future<Result<void>> removeCommentLike(String residenceId, String postId,
      String commentId, String userId);

  Future<Result<List<Comment>>> addComment(
      String docRes, String postId, Comment newComment,
      {String? commentId, String? initialComment});
}
