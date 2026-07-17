import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/comment_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/comment.dart';

class FirestoreCommentRepository implements ICommentRepository {
  final FirebaseFirestore _firestore;

  FirestoreCommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Résout le document Firestore du post (business `id` -> doc Firestore),
  /// nécessaire une seule fois avant d'ouvrir un stream sur ses sous-
  /// collections - contrairement à getComments/addComment, ce n'est fait
  /// qu'une fois par ouverture de stream, pas à chaque emission.
  Future<DocumentReference?> _resolvePostRef(
      String docRes, String postId) async {
    final postQuery = await _firestore
        .collection("residences")
        .doc(docRes)
        .collection("posts")
        .where("id", isEqualTo: postId)
        .limit(1)
        .get();
    if (postQuery.docs.isEmpty) return null;
    return postQuery.docs.first.reference;
  }

  @override
  Stream<List<Comment>> watchComments(String docRes, String postId) async* {
    final postRef = await _resolvePostRef(docRes, postId);
    if (postRef == null) {
      yield [];
      return;
    }
    yield* postRef
        .collection("comments")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<List<Comment>> watchReplies(
      String docRes, String postId, String commentId) async* {
    final postRef = await _resolvePostRef(docRes, postId);
    if (postRef == null) {
      yield [];
      return;
    }
    final commentQuery = await postRef
        .collection("comments")
        .where("id", isEqualTo: commentId)
        .limit(1)
        .get();
    if (commentQuery.docs.isEmpty) {
      yield [];
      return;
    }
    yield* commentQuery.docs.first.reference
        .collection("replies")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<int> watchTotalCommentCount(String docRes, String postId) async* {
    final postRef = await _resolvePostRef(docRes, postId);
    if (postRef == null) {
      yield 0;
      return;
    }
    final commentsRef = postRef.collection("comments");

    await for (final snapshot in commentsRef.snapshots()) {
      // Une requête d'agrégation par commentaire, mais en parallèle : un
      // post avec plusieurs commentaires attendait sinon chaque comptage
      // l'un après l'autre (latence perceptible au chargement du fil,
      // cumulée sur tous les posts affichés en même temps).
      final repliesCounts = await Future.wait(snapshot.docs.map(
          (commentDoc) => commentDoc.reference.collection("replies").count().get()));
      final total = snapshot.docs.length +
          repliesCounts.fold<int>(0, (acc, c) => acc + (c.count ?? 0));
      yield total;
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
