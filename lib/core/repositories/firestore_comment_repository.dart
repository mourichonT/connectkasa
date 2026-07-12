import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/comment_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/comment.dart';

class FirestoreCommentRepository implements ICommentRepository {
  final FirebaseFirestore _firestore;

  FirestoreCommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<Comment>>> getComments(
      String docRes, String postId) async {
    List<Comment> comments = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      for (var postSnapshot in querySnapshot.docs) {
        QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await _firestore
            .collection("residences")
            .doc(docRes)
            .collection("posts")
            .doc(postSnapshot.id)
            .collection("comments")
            .get();

        List<Comment> postComments = [];
        for (var commentSnapshot in commentsSnapshot.docs) {
          Comment comment = Comment.fromMap(commentSnapshot.data());

          // Récupérer directement les replies sans recharger le document parent
          QuerySnapshot<Map<String, dynamic>> repliesQuerySnapshot =
              await commentSnapshot.reference.collection('replies').get();

          if (repliesQuerySnapshot.docs.isNotEmpty) {
            List<Comment> replies = [];
            for (var replySnapshot in repliesQuerySnapshot.docs) {
              Map<String, dynamic> replyData = replySnapshot.data();
              replies.add(Comment.fromMap(replyData));
              replies.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            }
            comment.replies = replies;
          }
          postComments.add(comment);
        }
        postComments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        comments.addAll(postComments);
      }

      return Result.success(comments);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  Future<DocumentReference?> _getCommentRef(
      String residenceId, String postId, String commentId) async {
    final postQuery = await _firestore
        .collection("residences")
        .doc(residenceId)
        .collection("posts")
        .where("id", isEqualTo: postId)
        .limit(1)
        .get();

    if (postQuery.docs.isEmpty) {
      throw Exception("Post not found with ID: $postId");
    }

    final commentQuery = await _firestore
        .collection("residences")
        .doc(residenceId)
        .collection("posts")
        .doc(postQuery.docs.first.id)
        .collection("comments")
        .where("id", isEqualTo: commentId)
        .get();

    if (commentQuery.docs.isEmpty) throw Exception("Comment not found!");
    return commentQuery.docs.first.reference;
  }

  @override
  Future<Result<void>> updateCommentLikes(String residenceId, String postId,
      String commentId, String userId) async {
    try {
      final commentRef = await _getCommentRef(residenceId, postId, commentId);
      await commentRef!.update({
        'like': FieldValue.arrayUnion([userId])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeCommentLike(String residenceId, String postId,
      String commentId, String userId) async {
    try {
      final commentRef = await _getCommentRef(residenceId, postId, commentId);
      await commentRef!.update({
        'like': FieldValue.arrayRemove([userId])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Comment>>> addComment(
      String docRes, String postId, Comment newComment,
      {String? commentId, String? initialComment}) async {
    List<Comment> comments = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var postSnapshot in querySnapshot.docs) {
          if (newComment.originalCommment == false &&
              newComment.initialComment == null) {
            var parentCommentQuery = await _firestore
                .collection("residences")
                .doc(docRes)
                .collection("posts")
                .doc(postSnapshot.id)
                .collection("comments")
                .where("id", isEqualTo: commentId)
                .get();

            var parentCommentQueryID = parentCommentQuery.docs.first.id;
            if (parentCommentQueryID.isNotEmpty) {
              await _firestore
                  .collection("residences")
                  .doc(docRes)
                  .collection("posts")
                  .doc(postSnapshot.id)
                  .collection("comments")
                  .doc(parentCommentQueryID)
                  .collection("replies")
                  .add(newComment.toMap());
            } else {
              var parentCommentId = parentCommentQuery.docs.first.id;

              await _firestore
                  .collection("residences")
                  .doc(docRes)
                  .collection("posts")
                  .doc(postSnapshot.id)
                  .collection("comments")
                  .doc(parentCommentId)
                  .collection("replies")
                  .add(newComment.toMap());
            }
          } else if (newComment.originalCommment == false &&
              newComment.initialComment != null) {
            var replyCommentQuery = await _firestore
                .collection("residences")
                .doc(docRes)
                .collection("posts")
                .doc(postSnapshot.id)
                .collection("comments")
                .where("id", isEqualTo: initialComment)
                .get();

            var replyCommentQueryId = replyCommentQuery.docs.first.id;
            if (replyCommentQueryId.isNotEmpty) {
              await _firestore
                  .collection("residences")
                  .doc(docRes)
                  .collection("posts")
                  .doc(postSnapshot.id)
                  .collection("comments")
                  .doc(replyCommentQueryId)
                  .collection("replies")
                  .add(newComment.toMap());
            }
          } else {
            await _firestore
                .collection("residences")
                .doc(docRes)
                .collection("posts")
                .doc(postSnapshot.id)
                .collection("comments")
                .add(newComment.toMap());
          }

          QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await _firestore
              .collection("residences")
              .doc(docRes)
              .collection("posts")
              .doc(postSnapshot.id)
              .collection("comments")
              .get();

          for (var docSnapshot in commentsSnapshot.docs) {
            comments.add(Comment.fromMap(docSnapshot.data()));
          }
        }
      }

      return Result.success(comments);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
