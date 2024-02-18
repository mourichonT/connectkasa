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
          .get(); // Récupérer les posts avec l'ID spécifié

      if (querySnapshot.docs.isNotEmpty) {
        // Si un post correspondant à l'ID est trouvé
        for (var postSnapshot in querySnapshot.docs) {
          // Récupérer les commentaires pour ce post
          QuerySnapshot<Map<String, dynamic>> commentsSnapshot = await db
              .collection("Residence")
              .doc(docRes)
              .collection("post")
              .doc(postSnapshot.id) // Utiliser l'ID du post trouvé
              .collection("comments")
              .get(); // Récupérer tous les commentaires du post

          for (var docSnapshot in commentsSnapshot.docs) {
            // Convertir chaque document en objet Comment
            comments.add(Comment.fromMap(docSnapshot.data()));
            print(comments);
          }

          print(
              "Successfully retrieved comments for post with ID: ${postSnapshot.id}");
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
