import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/comment.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DataBasesServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<Post>> getAllPosts(String doc) async {
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await db.collection("Residence").doc(doc).collection("post").get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        posts.add(Post.fromMap(docSnapshot.data()));
      }
      print("Successfully completed");
    } catch (e) {
      print("Error completing in getAllpos: $e");
    }
    return posts;
  }

  Future<User?> getUserById(String numUser) async {
    User? user;
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .where("UID", isEqualTo: numUser)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        // S'il y a des documents correspondants, prenez le premier
        user = User.fromMap(querySnapshot.docs.first.data());
      }
      print("Successfully completed");
    } catch (e) {
      print("Error completing: $e");
    }

    return user;
  }

  Future<String?> getImageUrl(String pathImage) async {
    if (pathImage.isNotEmpty) {
      try {
        // Récupérer la référence de l'image depuis Firebase Storage
        final ref = FirebaseStorage.instance.ref().child(pathImage);
        // Obtenir l'URL de téléchargement de l'image
        final imageUrl = await ref.getDownloadURL();
        return imageUrl;
      } catch (e) {
        // Gérer les erreurs, par exemple l'image n'existe pas
        print("Erreur lors de la récupération de l'URL de l'image: $e");
        return null;
      }
    } else {
      return null; // Pas de chemin d'image défini
    }
  }

  Future<List<Lot?>> getLotByIdUser(String numUser) async {
    List<Lot?> lots = []; // Liste de lots
    try {
      // Commencer une transaction Firestore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Récupérer la référence de la collection "Residence"
        CollectionReference residenceRef =
            FirebaseFirestore.instance.collection("Residence");

        // Récupérer les documents de la collection "Residence"
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await residenceRef.get() as QuerySnapshot<Map<String, dynamic>>;

        // Parcourir chaque document de la collection "Residence"
        for (QueryDocumentSnapshot<Map<String, dynamic>> residenceDoc
            in querySnapshot.docs) {
          String residenceId = residenceDoc.id; // Identifiant du document
          // Ajouter l'identifiant du document à la liste
          //lots.add(residenceId);

          // Récupérer les lots de chaque résidence
          QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
              await residenceDoc.reference.collection("lot").get();

          // Récupérer les données du document de la résidence
          Map<String, dynamic> residenceData = residenceDoc.data()!;

          // Vérifier si idProprietaire ou idLocataire contient numUser
          // et récupérer les lots correspondants
          for (QueryDocumentSnapshot<Map<String, dynamic>> doc
              in lotQuerySnapshot.docs) {
            dynamic idProprietaire = doc.data()["idProprietaire"];
            dynamic idLocataire = doc.data()["idLocataire"];

            if ((idProprietaire is List && idProprietaire.contains(numUser)) ||
                (idLocataire is List && idLocataire.contains(numUser)) ||
                (idProprietaire is String && idProprietaire == numUser) ||
                (idLocataire is String && idLocataire == numUser)) {
              Lot? lot = Lot.fromMap(doc.data());
              // Ajouter les données de la résidence à chaque lot
              lot.residenceData = residenceData;
              lot.residenceId = residenceId;
              lots.add(lot); // Ajouter le lot correspondant à la liste
            }
          }
        }
      });

      print("Successfully completed");
    } catch (e) {
      print("Error completing in getLotByIduser2 function: $e");
    }

    return lots;
  }

  Future<void> updatePostLikes(
      String residenceId, String postId, String userId) async {
    try {
      // Obtenez une référence à la publication dans la base de données
      QuerySnapshot postQuery = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      // Vérifiez s'il y a un document correspondant à l'ID donné
      if (postQuery.docs.isNotEmpty) {
        // Récupérez la référence du premier document (il devrait y en avoir un seul)
        DocumentReference postRef = postQuery.docs.first.reference;

        // Récupérez les données du document
        DocumentSnapshot postSnapshot = await postRef.get();

        // Vérifiez si la publication existe
        if (postSnapshot.exists) {
          // Convertissez les données en Map<String, dynamic> de manière sûre
          Map<String, dynamic> postData =
              postSnapshot.data() as Map<String, dynamic>;

          // Obtenez la liste de likes actuelle
          List<dynamic> likes = postData['like'] ?? [];

          // Vérifiez si l'utilisateur est déjà dans la liste de likes
          bool userLiked = likes.contains(userId);

          // Ajoutez ou supprimez l'utilisateur de la liste de likes
          if (!userLiked) {
            // L'utilisateur n'a pas encore aimé la publication, alors ajoutez-le à la liste
            likes.add(userId);
          }

          // Mettez à jour la liste de likes dans les données de la publication
          postData['like'] = likes;

          // Mettez à jour la publication dans la base de données
          await postRef.update(postData);

          print("Successfully updated likes for post $postId");
        } else {
          throw Exception("Post not found!");
        }
      } else {
        throw Exception("Post not found!");
      }
    } catch (e) {
      print("Error updating likes for post $postId: $e");
      throw e;
    }
  }

  Future<void> removePostLike(
      String residenceId, String postId, String userId) async {
    try {
      // Obtenez une référence à la publication dans la base de données
      QuerySnapshot postQuery = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      // Vérifiez s'il y a un document correspondant à l'ID donné
      if (postQuery.docs.isNotEmpty) {
        // Récupérez la référence du premier document (il devrait y en avoir un seul)
        DocumentReference postRef = postQuery.docs.first.reference;

        // Récupérez les données du document
        DocumentSnapshot postSnapshot = await postRef.get();

        // Vérifiez si la publication existe
        if (postSnapshot.exists) {
          // Convertissez les données en Map<String, dynamic> de manière sûre
          Map<String, dynamic> postData =
              postSnapshot.data() as Map<String, dynamic>;

          // Obtenez la liste de likes actuelle
          List<dynamic> likes = postData['like'] ?? [];

          // Vérifiez si l'utilisateur est déjà dans la liste de likes
          if (likes.contains(userId)) {
            // Retirez l'utilisateur de la liste de likes
            likes.remove(userId);

            // Mettez à jour la liste de likes dans les données de la publication
            postData['like'] = likes;

            // Mettez à jour la publication dans la base de données
            await postRef.update(postData);

            print("Successfully removed like for post $postId by user $userId");
          } else {
            print("User $userId did not like post $postId");
          }
        } else {
          throw Exception("Post not found!");
        }
      } else {
        throw Exception("Post not found!");
      }
    } catch (e) {
      print("Error removing like for post $postId by user $userId: $e");
      throw e;
    }
  }

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

          if (!repliesQuerySnapshot.docs.isEmpty) {
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
    print(
        "je test UpdateCommentLikes =  residence :$residenceId, postId: $postId, commentId:$commentId, userId: $userId");
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
      throw e;
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
      throw e;
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
            print('parentCommentQuery = ${parentCommentQuery.docs.first.id}');

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

              print("Added reply to initial reply: $initialComment");
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

              print("Added reply to parent comment: $parentCommentId");
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

            print('JE SUIS LA ET JE PRINT initialComment = $initialComment');
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

              print("Added reply to initial reply: $initialComment");
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

  Future<List<Post>> getSignalements(String docRes, String postId) async {
    List<Post> posts = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("Residence")
              .doc(docRes)
              .collection("post")
              .where("id", isEqualTo: postId)
              .get();

      // Récupérer tous les listPosts correspondants
      for (var postSnapshot in querySnapshot.docs) {
        String postDocId = postSnapshot.id;
        Post post = Post.fromMap(postSnapshot.data());
        posts.add(post);

        // Vérifier chaque post pour les signalements
        for (var querySnapshot in posts) {
          print("ID : ${postDocId}");
          // Vérifier si le post a une collection de signalements
          QuerySnapshot<Map<String, dynamic>> signalementsSnapshot =
              await FirebaseFirestore.instance
                  .collection("Residence")
                  .doc(docRes)
                  .collection("post")
                  .doc(postDocId)
                  .collection("signalements")
                  .get();

          // Si des signalements existent pour ce post, les ajouter à la liste de signalements
          if (signalementsSnapshot.docs.isNotEmpty) {
            for (var signalementSnapshot in signalementsSnapshot.docs) {
              Post signalement = Post.fromMap(signalementSnapshot.data());
              posts.add(signalement);
            }
          } else {
            print(
                "Aucun signalement trouvé pour le post avec l'ID: ${querySnapshot.id}");
          }
        }
      }
    } catch (e) {
      print('Error fetching signalements: $e');
    }

    return posts;
  }
}
