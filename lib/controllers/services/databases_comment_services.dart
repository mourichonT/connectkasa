import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';

class DataBasesCommentServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<Comment>> getComments(String docRes, String postId) async {
    List<Comment> comments = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(docRes)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      for (var postSnapshot in querySnapshot.docs) {
        QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await db
            .collection("Residence")
            .doc(docRes)
            .collection("post")
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
            // Ajouter les réponses au commentaire
            comment.replies = replies;
          }
          postComments.add(comment);
        }
// Trier les commentaires par timestamp
        postComments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        comments.addAll(postComments);
      }
    } catch (e) {
      print("Error completing in getComments: $e");
    }

    return comments;
  }

  Future<DocumentReference?> _getCommentRef(
      String residenceId, String postId, String commentId) async {
    final postQuery = await FirebaseFirestore.instance
        .collection("Residence")
        .doc(residenceId)
        .collection("post")
        .where("id", isEqualTo: postId)
        .limit(1)
        .get();

    if (postQuery.docs.isEmpty) throw Exception("Post not found with ID: $postId");

    final commentQuery = await FirebaseFirestore.instance
        .collection("Residence")
        .doc(residenceId)
        .collection("post")
        .doc(postQuery.docs.first.id)
        .collection("comments")
        .where("id", isEqualTo: commentId)
        .get();

    if (commentQuery.docs.isEmpty) throw Exception("Comment not found!");
    return commentQuery.docs.first.reference;
  }

  Future<void> updateCommentLikes(String residenceId, String postId,
      String commentId, String userId) async {
    try {
      final commentRef = await _getCommentRef(residenceId, postId, commentId);
      await commentRef!.update({'like': FieldValue.arrayUnion([userId])});
    } catch (e) {
      print("Error updating likes for comment $commentId: $e");
      rethrow;
    }
  }

  Future<void> removeCommentLike(String residenceId, String postId,
      String commentId, String userId) async {
    try {
      final commentRef = await _getCommentRef(residenceId, postId, commentId);
      await commentRef!.update({'like': FieldValue.arrayRemove([userId])});
    } catch (e) {
      print("Error removing like for comment $commentId by user $userId: $e");
      rethrow;
    }
  }

  Future<List<Comment>> addComment(
      String docRes, String postId, Comment newComment,
      {String? commentId, String? initialComment}) async {
    List<Comment> comments = [];
    try {
      // Récupérer les posts avec l'ID spécifié
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(docRes)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si un post correspondant à l'ID est trouvé
        for (var postSnapshot in querySnapshot.docs) {
          // Ajouter le nouveau commentaire à la collection
          if (newComment.originalCommment == false &&
              newComment.initialComment == null) {
            // Effectuer une requête pour obtenir le document qui correspond à la valeur de commentId
            var parentCommentQuery = await db
                .collection("Residence")
                .doc(docRes)
                .collection("post")
                .doc(postSnapshot.id)
                .collection("comments")
                .where("id", isEqualTo: commentId)
                .get();

            var parentCommentQueryID = parentCommentQuery.docs.first.id;
            // Vérifier s'il existe un document correspondant
            if (parentCommentQueryID.isNotEmpty) {
              // Ajouter la réponse de la réponse au commentaire initial
              await db
                  .collection("Residence")
                  .doc(docRes)
                  .collection("post")
                  .doc(postSnapshot.id)
                  .collection("comments")
                  .doc(parentCommentQueryID)
                  .collection("replies")
                  .add(newComment.toMap());
            } else {
              var parentCommentId = parentCommentQuery.docs.first.id;

              // Ajouter le nouveau commentaire à la collection "replies"
              await db
                  .collection("Residence")
                  .doc(docRes)
                  .collection("post")
                  .doc(postSnapshot.id)
                  .collection("comments")
                  .doc(parentCommentId)
                  .collection("replies")
                  .add(newComment.toMap());
            }
          } else if (newComment.originalCommment == false &&
              newComment.initialComment != null) {
            var replyCommentQuery = await db
                .collection("Residence")
                .doc(docRes)
                .collection("post")
                .doc(postSnapshot.id)
                .collection("comments")
                .where("id", isEqualTo: initialComment)
                .get();

            var replyCommentQueryId = replyCommentQuery.docs.first.id;
            if (replyCommentQueryId.isNotEmpty) {
              // Ajouter la réponse de la réponse au commentaire initial
              await db
                  .collection("Residence")
                  .doc(docRes)
                  .collection("post")
                  .doc(postSnapshot.id)
                  .collection("comments")
                  .doc(replyCommentQueryId)
                  .collection("replies")
                  .add(newComment.toMap());
            } else {
              print("impossible de poster la reponse");
            }
          } else {
            // Si parentCommentId n'est pas fourni, cela signifie que nous ajoutons un commentaire normal
            await db
                .collection("Residence")
                .doc(docRes)
                .collection("post")
                .doc(postSnapshot.id)
                .collection("comments")
                .add(newComment.toMap()); // Ajouter le nouveau commentaire
          }

          // Récupérer tous les commentaires du post
          QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await db
              .collection("Residence")
              .doc(docRes)
              .collection("post")
              .doc(postSnapshot.id)
              .collection("comments")
              .get();

          // Convertir chaque document en objet Comment et les ajouter à la liste de commentaires
          for (var docSnapshot in commentsSnapshot.docs) {
            comments.add(Comment.fromMap(docSnapshot.data()));
          }
        }
      } else {
        print("Post with ID $postId does not exist");
      }
    } catch (e) {
      print("Error completing in getComments: $e");
    }
    return comments;
  }
}
