import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/post.dart';

class DataBasesPostServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<Post> getPost(String residenceId, String postId, String userId) async {
    try {
      // Obtenez une référence à la publication dans la base de données
      QuerySnapshot postQuery = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      // Vérifie si la requête a retourné des documents
      if (postQuery.docs.isNotEmpty) {
        // Si oui, récupère le premier document (il ne devrait y en avoir qu'un)
        DocumentSnapshot postDoc = postQuery.docs.first;

        // Crée une instance de Post à partir du document
        return Post.fromMap(postDoc.data() as Map<String, dynamic>);
      } else {
        throw Exception(
            'Aucune publication trouvée avec l\'ID $postId dans la résidence $residenceId');
      }
    } catch (e) {
      // Gère les erreurs ici
      print(
          'Une erreur s\'est produite lors de la récupération de la publication: $e');
      // Lance l'erreur pour que l'appelant puisse la gérer si nécessaire
      throw e;
    }
  }

  Future<List<Post>> getAllAnnonces(String doc) async {
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(doc)
          .collection("post")
          .where('type', isEqualTo: 'annonces')
          //.orderBy('timeStamp', descending: true)
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        posts.add(Post.fromMap(docSnapshot.data()));
      }
    } catch (e) {
      print("Error completing in getAllpos: $e");
    }
    return posts;
  }

  Future<List<Post>> getAnnonceById(String doc, String uid) async {
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(doc)
          .collection("post")
          .where('user', isEqualTo: uid)
          .where('type', isEqualTo: 'annonces')
          //.orderBy('timeStamp', descending: true)
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        posts.add(Post.fromMap(docSnapshot.data()));
      }
    } catch (e) {
      print("Error completing in getAllpos: $e");
    }
    return posts;
  }

  Future<List<Post>> getAllPostsWithFilters(
      {required String doc,
      List<String?>? locationElement,
      String? locationDetails,
      String? type}) async {
    List<Post> posts = [];
    try {
      Query<Map<String, dynamic>> query =
          db.collection("Residence").doc(doc).collection("post");

      if (locationElement != null && locationElement.isNotEmpty) {
        // Utilisez whereIn pour filtrer les documents ayant location_element
        query = query.where('location_element', whereIn: locationElement);

        if (locationDetails != null && locationDetails.isNotEmpty) {
          query = query.where('location_details', isEqualTo: locationDetails);
        }

        if (type != null && type.isNotEmpty) {
          query = query.where('type', isEqualTo: type);
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();

        for (var docSnapshot in querySnapshot.docs) {
          posts.add(Post.fromMap(docSnapshot.data()));
        }
      }
    } catch (e) {
      // Handle the error appropriately, e.g., return an error object or rethrow
      print("Error completing in getAllPostsWithFilters: $e");
    }
    return posts;
  }

  Future<List<Post>> getAllPosts(String doc) async {
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(doc)
          .collection("post")
          .orderBy('timeStamp', descending: true)
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        posts.add(Post.fromMap(docSnapshot.data()));
      }
    } catch (e) {
      print("Error completing in getAllpos: $e");
    }
    return posts;
  }

  Future<Post?> addPost(Post newPost, String docRes) async {
    try {
      // Si aucun post correspondant n'est trouvé, ajouter le nouveau post à la collection
      await db
          .collection("Residence")
          .doc(docRes)
          .collection("post")
          .add(newPost.toMap());
    } catch (e) {
      print("Impossible de poster le nouveau Post: $e");
    }

    return newPost;
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
                "Aucun signalement supplémentaire trouvé pour le post avec l'ID: ${querySnapshot.id}");
          }
        }
      }
    } catch (e) {
      print('Error fetching signalements: $e');
    }

    return posts;
  }

  Future<Post?> getUpdatePost(String docRes, String postId) async {
    Post? post;

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(docRes)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // S'il y a des documents correspondants, prenez le premier
        post = Post.fromMap(querySnapshot.docs.first.data());
      }
    } catch (e) {
      print("impossible de récupérer le Post");
    }

    return post;
  }

  Future<void> updatePostParticipants(
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
          List<dynamic> participants = postData['participants'] ?? [];

          // Vérifiez si l'utilisateur est déjà dans la liste de likes
          bool userParticiped = participants.contains(userId);

          // Ajoutez ou supprimez l'utilisateur de la liste de likes
          if (!userParticiped) {
            // L'utilisateur n'a pas encore aimé la publication, alors ajoutez-le à la liste
            participants.add(userId);
          }

          // Mettez à jour la liste de likes dans les données de la publication
          postData['participants'] = participants;

          // Mettez à jour la publication dans la base de données
          await postRef.update(postData);
        } else {
          throw Exception("Post not found!");
        }
      } else {
        throw Exception("Post not found!");
      }
    } catch (e) {
      print("Error updating participants for post $postId: $e");
      throw e;
    }
  }

  Future<void> removePostParticipants(
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
          List<dynamic> userParticiped = postData['participants'] ?? [];

          // Vérifiez si l'utilisateur est déjà dans la liste de likes
          if (userParticiped.contains(userId)) {
            // Retirez l'utilisateur de la liste de likes
            userParticiped.remove(userId);

            // Mettez à jour la liste de likes dans les données de la publication
            postData['participants'] = userParticiped;

            // Mettez à jour la publication dans la base de données
            await postRef.update(postData);
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
      print("Error removing Participants for post $postId by user $userId: $e");
      throw e;
    }
  }
}
