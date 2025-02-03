import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/post.dart';

class DataBasesPostServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<Post> getPost(String residenceId, String postId) async {
    try {
      // Obtenez une référence à la publication dans la collection principale "post"
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
        // Si le post n'est pas trouvé dans la collection principale "post",
        // recherche dans les sous-collections "signalements" de la collection "post"
        QuerySnapshot postsQuery = await FirebaseFirestore.instance
            .collection("Residence")
            .doc(residenceId)
            .collection("post")
            .get();

        for (DocumentSnapshot postDoc in postsQuery.docs) {
          // Vérifie si le document contient une sous-collection "signalements"
          QuerySnapshot signalementsQuery = await postDoc.reference
              .collection("signalements")
              .where("id", isEqualTo: postId)
              .get();

          // Si des signalements ont été trouvés, retourne le document de signalement
          if (signalementsQuery.docs.isNotEmpty) {
            DocumentSnapshot postWithSignalementsDoc =
                signalementsQuery.docs.first;
            return Post.fromMap(
                postWithSignalementsDoc.data() as Map<String, dynamic>);
          }
        }

        // Si aucun post n'est trouvé ni dans la collection principale ni dans les signalements
        throw Exception(
            'Aucune publication trouvée avec l\'ID $postId dans la résidence $residenceId');
      }
    } catch (e) {
      // Gère les erreurs ici
      print(
          'Une erreur s\'est produite lors de la récupération de la publication: $e');
      // Lance l'erreur pour que l'appelant puisse la gérer si nécessaire
      rethrow;
    }
  }

  Future<void> removePost(String residenceId, String postId) async {
    try {
      // Recherchez le document du post en utilisant l'ID
      QuerySnapshot<Map<String, dynamic>> postQuery = await FirebaseFirestore
          .instance
          .collection("Residence")
          .doc(residenceId)
          .collection("post")
          .where("id", isEqualTo: postId)
          .get();

      // Vérifiez si des documents correspondent à la condition
      if (postQuery.docs.isNotEmpty) {
        // Supprimez le premier document trouvé (il ne devrait y en avoir qu'un)
        DocumentSnapshot postDoc = postQuery.docs.first;
        await postDoc.reference.delete();
      } else {
        throw Exception(
            'Aucune publication trouvée avec l\'ID $postId dans la résidence $residenceId');
      }
    } catch (e) {
      // Gère les erreurs ici
      print(
          'Une erreur s\'est produite lors de la suppression de la publication: $e');
      // Lance l'erreur pour que l'appelant puisse la gérer si nécessaire
      rethrow;
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
      List<String?>? type,
      String? dateFrom,
      String? dateTo,
      List<String?>? statut}) async {
    List<Post> posts = [];
    try {
      Query<Map<String, dynamic>> baseQuery =
          db.collection("Residence").doc(doc).collection("post");

      // Convert date strings to Timestamps
      Timestamp? timestampFrom;
      Timestamp? timestampTo;

      if (dateFrom != null && dateFrom.isNotEmpty) {
        timestampFrom = Timestamp.fromDate(DateTime.parse(dateFrom));
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        timestampTo = Timestamp.fromDate(DateTime.parse(dateTo));
      }

      // Generate all combinations of locationElement, type, dateFrom, dateTo, and statut
      List<List<dynamic>> combinations = [];
      if (locationElement != null &&
          locationElement.isNotEmpty &&
          type != null &&
          type.isNotEmpty &&
          statut != null &&
          statut.isNotEmpty) {
        for (var loc in locationElement) {
          for (var t in type) {
            for (var s in statut) {
              combinations.add([loc, t, timestampFrom, timestampTo, s]);
            }
          }
        }
      } else if (locationElement != null &&
          locationElement.isNotEmpty &&
          type != null &&
          type.isNotEmpty) {
        for (var loc in locationElement) {
          for (var t in type) {
            combinations.add([loc, t, timestampFrom, timestampTo, null]);
          }
        }
      } else if (locationElement != null && locationElement.isNotEmpty) {
        for (var loc in locationElement) {
          combinations.add([loc, null, timestampFrom, timestampTo, null]);
        }
      } else if (type != null && type.isNotEmpty) {
        for (var t in type) {
          combinations.add([null, t, timestampFrom, timestampTo, null]);
        }
      } else if (statut != null && statut.isNotEmpty) {
        for (var s in statut) {
          combinations.add([null, null, timestampFrom, timestampTo, s]);
        }
      } else {
        combinations.add([null, null, timestampFrom, timestampTo, null]);
      }

      // Perform queries for each combination
      for (var combo in combinations) {
        Query<Map<String, dynamic>> query = baseQuery;

        if (combo[0] != null) {
          query = query.where('location_element', isEqualTo: combo[0]);
        }
        if (combo[1] != null) {
          query = query.where('type', isEqualTo: combo[1]);
        }
        if (combo[2] != null) {
          query = query.where('timeStamp', isGreaterThanOrEqualTo: combo[2]);
        }
        if (combo[3] != null) {
          query = query.where('timeStamp', isLessThanOrEqualTo: combo[3]);
        }
        if (combo[4] != null) {
          query = query.where('statu', isEqualTo: combo[4]);
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

  Future<List<Post>> getAllPostsToModify(String doc) async {
    List<Post> posts = [];
    try {
      // Obtenez une référence à tous les documents de la collection principale "post"
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(doc)
          .collection("post")
          .orderBy('timeStamp', descending: true)
          .get();

      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        Post post = Post.fromMap(docSnapshot.data());

        // Ajouter le post à la liste des posts
        posts.add(post);

        // Récupérer tous les documents de la sous-collection "signalements" pour ce post
        QuerySnapshot<Map<String, dynamic>> signalementsQuery =
            await docSnapshot.reference.collection("signalements").get();

        // Convertir chaque document de signalement en objet Post et les ajouter à la liste des posts
        for (var signalementSnapshot in signalementsQuery.docs) {
          Post signalementPost = Post.fromMap(signalementSnapshot.data());
          posts.add(signalementPost);
        }
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<Post?> updatePost(
      Post updatedPost, String docRes, String postId) async {
    try {
      // Rechercher le document avec le champ id égal à postId dans la collection principale "post"
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(docRes)
          .collection("post")
          .where('id', isEqualTo: postId)
          .get();

      // Si le document est trouvé dans la collection principale, mettez-le à jour
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await FirebaseFirestore.instance
            .collection("Residence")
            .doc(docRes)
            .collection("post")
            .doc(documentSnapshot.id)
            .update(updatedPost.toMap());

        print("Post mis à jour avec succès dans la collection principale");
        return updatedPost;
      } else {
        // Si le post n'est pas trouvé dans la collection principale "post",
        // recherche dans les sous-collections "signalements" de la collection "post"
        QuerySnapshot postsQuery = await FirebaseFirestore.instance
            .collection("Residence")
            .doc(docRes)
            .collection("post")
            .get();

        for (DocumentSnapshot postDoc in postsQuery.docs) {
          // Vérifie si le document contient une sous-collection "signalements"
          QuerySnapshot signalementsQuery = await postDoc.reference
              .collection("signalements")
              .where("id", isEqualTo: postId)
              .get();

          // Si des signalements ont été trouvés, mettez à jour le document de signalement
          if (signalementsQuery.docs.isNotEmpty) {
            DocumentSnapshot postWithSignalementsDoc =
                signalementsQuery.docs.first;
            await postWithSignalementsDoc.reference.update(updatedPost.toMap());

            print("Post mis à jour avec succès dans les signalements");
            return updatedPost;
          }
        }

        // Si aucun post n'est trouvé ni dans la collection principale ni dans les signalements
        print(
            "Aucun post correspondant trouvé ni dans la collection principale ni dans les signalements");
        return null;
      }
    } catch (e) {
      print("Impossible de mettre à jour le Post: $e");
      rethrow;
    }
  }

  Future<List<Post>> rechercheFirestore(String saisie, String residence) async {
    List<Post> annonceTrouvees = [];

    // Récupérer une référence à la collection
    CollectionReference collectionReference = FirebaseFirestore.instance
        .collection("Residence")
        .doc(residence)
        .collection("post");

    // Effectuer la requête de recherche
    QuerySnapshot querySnapshot = await collectionReference.get();

    // Boucler à travers les documents
    for (var doc in querySnapshot.docs) {
      // Convertir les données en un objet Residence
      Post annonce = Post.fromMap(doc.data()! as Map<String, dynamic>);

      // Vérifier si les champs requis contiennent la saisie
      if ((annonce.title.toLowerCase().contains(saisie.toLowerCase())) ||
          (annonce.description.toLowerCase().contains(saisie.toLowerCase()))) {
        // Ajouter la résidence trouvée à la liste des résidences trouvées
        annonceTrouvees.add(annonce);
      }
    }

    return annonceTrouvees;
  }

  Future<List<Post>> getAllAnnoncesWithFilters(
      {required String doc,
      List<String?>? subtype,
      String? dateFrom,
      String? dateTo,
      int? priceMin,
      int? priceMax}) async {
    List<Post> annonces = [];
    try {
      Query<Map<String, dynamic>> baseQuery = db
          .collection("Residence")
          .doc(doc)
          .collection("post")
          .where('type', isEqualTo: 'annonces');

      // Convertir les chaînes de date en Timestamp
      Timestamp? timestampFrom;
      Timestamp? timestampTo;

      if (dateFrom != null && dateFrom.isNotEmpty) {
        timestampFrom = Timestamp.fromDate(DateTime.parse(dateFrom));
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        timestampTo = Timestamp.fromDate(DateTime.parse(dateTo));
      }

      // Générer toutes les combinaisons de subtype, dateFrom, dateTo, priceMin et priceMax
      List<List<dynamic>> combinations = [];
      if (subtype != null && subtype.isNotEmpty) {
        for (var st in subtype) {
          combinations
              .add([st, timestampFrom, timestampTo, priceMin, priceMax]);
        }
      } else {
        combinations
            .add([null, timestampFrom, timestampTo, priceMin, priceMax]);
      }

      // Effectuer des requêtes pour chaque combinaison
      for (var combo in combinations) {
        Query<Map<String, dynamic>> query = baseQuery;

        if (combo[0] != null) {
          query = query.where('subtype', isEqualTo: combo[0]);
        }
        if (combo[1] != null) {
          query = query.where('timeStamp', isGreaterThanOrEqualTo: combo[1]);
        }
        if (combo[2] != null) {
          query = query.where('timeStamp', isLessThanOrEqualTo: combo[2]);
        }
        if (combo[3] != null) {
          query = query.where('price', isGreaterThanOrEqualTo: combo[3]);
        }
        if (combo[4] != null) {
          query = query.where('price', isLessThanOrEqualTo: combo[4]);
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
        for (var docSnapshot in querySnapshot.docs) {
          annonces.add(Post.fromMap(docSnapshot.data()));
        }
      }
    } catch (e) {
      // Gérer l'erreur de manière appropriée, par exemple, retourner un objet d'erreur ou relancer l'exception
      print("Erreur dans getAllAnnoncesWithFilters: $e");
    }
    return annonces;
  }

  Future<List<Post>> getSignalementsList(String docRes, String postId) async {
    List<Post> signalements = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("Residence")
              .doc(docRes)
              .collection("post")
              .where("id", isEqualTo: postId)
              .get();

      // Récupérer tous les posts correspondants
      for (var postSnapshot in querySnapshot.docs) {
        String postDocId = postSnapshot.id;

        // Récupérer les signalements pour chaque post
        QuerySnapshot<Map<String, dynamic>> signalementsSnapshot =
            await FirebaseFirestore.instance
                .collection("Residence")
                .doc(docRes)
                .collection("post")
                .doc(postDocId)
                .collection("signalements")
                .get();

        // Ajouter les signalements à la liste
        for (var signalementSnapshot in signalementsSnapshot.docs) {
          Post signalement = Post.fromMap(signalementSnapshot.data());
          signalements.add(signalement);
        }
      }
    } catch (e) {
      print('Error fetching signalements: $e');
    }

    return signalements;
  }

  Future<Map<String, int>> getMinMaxPrices(String doc) async {
    int priceMin = 999999999; // Initialisation à une grande valeur positive
    int priceMax = 0; // Initialisation à une petite valeur négative

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(doc)
          .collection("post")
          .where('type', isEqualTo: 'annonces')
          .get();

      for (var docSnapshot in querySnapshot.docs) {
        var post = Post.fromMap(docSnapshot.data());
        if (post.price! < priceMin) {
          priceMin = post.price!;
        }
        if (post.price! > priceMax) {
          priceMax = post.price!;
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération des annonces: $e");
    }

    return {'priceMin': priceMin, 'priceMax': priceMax};
  }
}
