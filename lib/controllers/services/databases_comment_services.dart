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

          // Accéder au document de commentaire pour vérifier si la sous-collection "replies" existe
          DocumentSnapshot<Map<String, dynamic>> commentDocSnapshot = await db
              .collection("Residence")
              .doc(docRes)
              .collection("post")
              .doc(postSnapshot.id)
              .collection("comments")
              .doc(commentSnapshot.id)
              .get();

          // Vérifier si la sous-collection "replies" existe dans le document de commentaire
          QuerySnapshot<Map<String, dynamic>> repliesQuerySnapshot =
              await commentDocSnapshot.reference.collection('replies').get();

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

  Future<void> updateCommentLikes(String residenceId, String postId,
      String commentId, String userId) async {
    try {
      // Obtenez une référence au commentaire dans la base de données
      QuerySnapshot commentQuery = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("post")
          .where("id", isEqualTo: postId)
          .limit(1)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          String postId = querySnapshot.docs.first.id;
          return FirebaseFirestore.instance
              .collection("Residence")
              .doc(residenceId)
              .collection("post")
              .doc(postId)
              .collection("comments")
              .where("id", isEqualTo: commentId)
              .get();
        } else {
          throw Exception("Post not found with ID: $postId");
        }
      });
      // Vérifiez s'il y a un document correspondant à l'ID donné
      if (commentQuery.docs.isNotEmpty) {
        // Récupérez la référence du premier document (il devrait y en avoir un seul)
        DocumentReference commentRef = commentQuery.docs.first.reference;

        // Récupérez les données du document
        DocumentSnapshot commentSnapshot = await commentRef.get();

        // Vérifiez si la publication existe
        if (commentSnapshot.exists) {
          // Convertissez les données en Map<String, dynamic> de manière sûre
          Map<String, dynamic> commentData =
              commentSnapshot.data() as Map<String, dynamic>;

          // Obtenez la liste de likes actuelle
          List<dynamic> likes = commentData['like'] ?? [];

          // Vérifiez si l'utilisateur est déjà dans la liste de likes
          bool userLiked = likes.contains(userId);

          // Ajoutez ou supprimez l'utilisateur de la liste de likes
          if (!userLiked) {
            // L'utilisateur n'a pas encore aimé la publication, alors ajoutez-le à la liste
            likes.add(userId);
          }

          // Mettez à jour la liste de likes dans les données de la publication
          commentData['like'] = likes;

          // Mettez à jour la publication dans la base de données
          await commentRef.update(commentData);

          print("Successfully updated likes for comment $commentId");
        } else {
          throw Exception("comment not found!");
        }
      } else {
        throw Exception("comment not found!");
      }
    } catch (e) {
      print("Error updating likes for comment $commentId: $e");
      rethrow;
    }
  }

  Future<void> removeCommentLike(String residenceId, String postId,
      String commentId, String userId) async {
    try {
      // Obtenez une référence au commentaire dans la base de données
      QuerySnapshot commentQuery = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("post")
          .where("id", isEqualTo: postId)
          .limit(1)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          String postId = querySnapshot.docs.first.id;
          return FirebaseFirestore.instance
              .collection("Residence")
              .doc(residenceId)
              .collection("post")
              .doc(postId)
              .collection("comments")
              .where("id", isEqualTo: commentId)
              .get();
        } else {
          throw Exception("Post not found with ID: $postId");
        }
      });

      // Vérifiez s'il y a un document correspondant à l'ID donné
      if (commentQuery.docs.isNotEmpty) {
        // Récupérez la référence du premier document (il devrait y en avoir un seul)
        DocumentReference commentRef = commentQuery.docs.first.reference;

        // Récupérez les données du document
        DocumentSnapshot commentSnapshot = await commentRef.get();

        // Vérifiez si la publication existe
        if (commentSnapshot.exists) {
          // Convertissez les données en Map<String, dynamic> de manière sûre
          Map<String, dynamic> commentData =
              commentSnapshot.data() as Map<String, dynamic>;

          // Obtenez la liste de likes actuelle
          List<dynamic> likes = commentData['like'] ?? [];

          // Vérifiez si l'utilisateur est déjà dans la liste de likes
          if (likes.contains(userId)) {
            // Retirez l'utilisateur de la liste de likes
            likes.remove(userId);

            // Mettez à jour la liste de likes dans les données de la publication
            commentData['like'] = likes;

            // Mettez à jour la publication dans la base de données
            await commentRef.update(commentData);

            print(
                "Successfully removed like for comment $commentId by user $userId");
          } else {
            print("User $userId did not like comment $commentId");
          }
        } else {
          throw Exception("Comment not found!");
        }
      } else {
        throw Exception("Comment not found!");
      }
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
