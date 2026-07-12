import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/post.dart';

class FirestorePostRepository implements IPostRepository {
  final FirebaseFirestore _firestore;

  FirestorePostRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<Post>> getPost(String residenceId, String postId) async {
    try {
      QuerySnapshot postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (postQuery.docs.isNotEmpty) {
        DocumentSnapshot postDoc = postQuery.docs.first;
        return Result.success(
            Post.fromMap(postDoc.data() as Map<String, dynamic>));
      }

      QuerySnapshot postsQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .get();

      for (DocumentSnapshot postDoc in postsQuery.docs) {
        QuerySnapshot signalementsQuery = await postDoc.reference
            .collection("signalements")
            .where("id", isEqualTo: postId)
            .get();

        if (signalementsQuery.docs.isNotEmpty) {
          DocumentSnapshot postWithSignalementsDoc =
              signalementsQuery.docs.first;
          return Result.success(Post.fromMap(
              postWithSignalementsDoc.data() as Map<String, dynamic>));
        }
      }

      return Result.failure(NotFoundException(
          'Aucune publication trouvée avec l\'ID $postId dans la résidence $residenceId'));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removePost(String residenceId, String postId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (postQuery.docs.isEmpty) {
        return Result.failure(NotFoundException(
            'Aucune publication trouvée avec l\'ID $postId dans la résidence $residenceId'));
      }

      DocumentSnapshot postDoc = postQuery.docs.first;
      await postDoc.reference.delete();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getAllAnnonces(String doc) async {
    // residenceId transitoirement vide le temps que my_nav_bar.dart résout
    // le vrai lot (placeholder _defaultLot au tout premier build) : pas une
    // erreur, juste "pas encore de résidence" -> pas de posts. Sans ce
    // garde-fou, Firestore lève une ArgumentError brute sur .doc("").
    if (doc.isEmpty) {
      return const Result.success([]);
    }
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .where('type', isEqualTo: 'annonces')
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        posts.add(Post.fromMap(docSnapshot.data()));
      }
      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getAnnonceById(String doc, String uid) async {
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .where('user', isEqualTo: uid)
          .where('type', isEqualTo: 'annonces')
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        posts.add(Post.fromMap(docSnapshot.data()));
      }
      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getAllPostsWithFilters({
    required String doc,
    List<String?>? locationElement,
    List<String?>? type,
    String? dateFrom,
    String? dateTo,
    List<String?>? statut,
  }) async {
    List<Post> posts = [];
    try {
      Query<Map<String, dynamic>> baseQuery =
          _firestore.collection("residences").doc(doc).collection("posts");

      Timestamp? timestampFrom;
      Timestamp? timestampTo;

      if (dateFrom != null && dateFrom.isNotEmpty) {
        timestampFrom = Timestamp.fromDate(DateTime.parse(dateFrom));
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        timestampTo = Timestamp.fromDate(DateTime.parse(dateTo));
      }

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

      for (var combo in combinations) {
        Query<Map<String, dynamic>> query = baseQuery;

        if (combo[0] != null) {
          query = query.where('location.locationElements', isEqualTo: combo[0]);
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
          query = query.where('statut', isEqualTo: combo[4]);
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
        for (var docSnapshot in querySnapshot.docs) {
          posts.add(Post.fromMap(docSnapshot.data()));
        }
      }
      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getAllPosts(String doc) async {
    // Voir commentaire dans getAllAnnonces : residenceId transitoirement
    // vide au tout premier build de my_nav_bar.dart.
    if (doc.isEmpty) {
      return const Result.success([]);
    }
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .orderBy('timeStamp', descending: true)
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        posts.add(Post.fromMap(docSnapshot.data()));
      }
      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getAllPostsToModify(String doc) async {
    // Voir commentaire dans getAllAnnonces : residenceId transitoirement
    // vide au tout premier build de my_nav_bar.dart.
    if (doc.isEmpty) {
      return const Result.success([]);
    }
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .orderBy('timeStamp', descending: true)
          .get();

      for (var docSnapshot in querySnapshot.docs) {
        Post post = Post.fromMap(docSnapshot.data());
        posts.add(post);

        QuerySnapshot<Map<String, dynamic>> signalementsQuery =
            await docSnapshot.reference.collection("signalements").get();

        for (var signalementSnapshot in signalementsQuery.docs) {
          Post signalementPost = Post.fromMap(signalementSnapshot.data());
          posts.add(signalementPost);
        }
      }
      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<PostPage>> getPostsPage(
    String doc, {
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    if (doc.isEmpty) {
      return const Result.success(
          PostPage(posts: [], lastDocument: null, hasMore: false));
    }
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .orderBy('timeStamp', descending: true)
          .limit(limit + 1);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final querySnapshot = await query.get();
      final hasMore = querySnapshot.docs.length > limit;
      final pageDocs = hasMore
          ? querySnapshot.docs.sublist(0, limit)
          : querySnapshot.docs;
      final posts =
          pageDocs.map((docSnapshot) => Post.fromMap(docSnapshot.data())).toList();
      return Result.success(PostPage(
        posts: posts,
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      ));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<PostPage>> getPostsToModifyPage(
    String doc, {
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    if (doc.isEmpty) {
      return const Result.success(
          PostPage(posts: [], lastDocument: null, hasMore: false));
    }
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .orderBy('timeStamp', descending: true)
          .limit(limit + 1);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final querySnapshot = await query.get();
      final hasMore = querySnapshot.docs.length > limit;
      final pageDocs = hasMore
          ? querySnapshot.docs.sublist(0, limit)
          : querySnapshot.docs;

      final posts = <Post>[];
      for (final docSnapshot in pageDocs) {
        posts.add(Post.fromMap(docSnapshot.data()));

        final signalementsQuery =
            await docSnapshot.reference.collection("signalements").get();
        for (final signalementSnapshot in signalementsQuery.docs) {
          posts.add(Post.fromMap(signalementSnapshot.data()));
        }
      }
      return Result.success(PostPage(
        posts: posts,
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      ));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Post?>> addPost(Post newPost, String docRes) async {
    try {
      await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .add(newPost.toMap());
      return Result.success(newPost);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Post?>> addSignalement(
      Post newSignalement, String docRes, String idPost) async {
    try {
      await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .doc(idPost)
          .collection("signalements")
          .doc(newSignalement.id)
          .set(newSignalement.toMap());
      return Result.success(newSignalement);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updatePostLikes(
      String residenceId, String postId, String userId) async {
    try {
      final postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (postQuery.docs.isEmpty) {
        return Result.failure(NotFoundException("Post not found!"));
      }

      await postQuery.docs.first.reference.update({
        'like': FieldValue.arrayUnion([userId])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removePostLike(
      String residenceId, String postId, String userId) async {
    try {
      final postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (postQuery.docs.isEmpty) {
        return Result.failure(NotFoundException("Post not found!"));
      }

      await postQuery.docs.first.reference.update({
        'like': FieldValue.arrayRemove([userId])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getSignalements(
      String docRes, String postId) async {
    List<Post> posts = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      for (var postSnapshot in querySnapshot.docs) {
        String postDocId = postSnapshot.id;
        Post post = Post.fromMap(postSnapshot.data());
        posts.add(post);

        QuerySnapshot<Map<String, dynamic>> signalementsSnapshot =
            await _firestore
                .collection("residences")
                .doc(docRes)
                .collection("posts")
                .doc(postDocId)
                .collection("signalements")
                .get();

        for (var signalementSnapshot in signalementsSnapshot.docs) {
          Post signalement = Post.fromMap(signalementSnapshot.data());
          posts.add(signalement);
        }
      }
      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Post?>> getUpdatePost(String docRes, String postId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Result.success(Post.fromMap(querySnapshot.docs.first.data()));
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updatePostParticipants(
      String residenceId, String postId, String userId) async {
    try {
      final postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (postQuery.docs.isEmpty) {
        return Result.failure(NotFoundException("Post not found!"));
      }

      await postQuery.docs.first.reference.update({
        'participants': FieldValue.arrayUnion([userId])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removePostParticipants(
      String residenceId, String postId, String userId) async {
    try {
      final postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      if (postQuery.docs.isEmpty) {
        return Result.failure(NotFoundException("Post not found!"));
      }

      await postQuery.docs.first.reference.update({
        'participants': FieldValue.arrayRemove([userId])
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Post?>> updatePost(
      Post updatedPost, String docRes, String postId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where('id', isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await _firestore
            .collection("residences")
            .doc(docRes)
            .collection("posts")
            .doc(documentSnapshot.id)
            .update(updatedPost.toUpdateMap());

        return Result.success(updatedPost);
      }

      QuerySnapshot postsQuery = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .get();

      for (DocumentSnapshot postDoc in postsQuery.docs) {
        QuerySnapshot signalementsQuery = await postDoc.reference
            .collection("signalements")
            .where("id", isEqualTo: postId)
            .get();

        if (signalementsQuery.docs.isNotEmpty) {
          DocumentSnapshot postWithSignalementsDoc =
              signalementsQuery.docs.first;
          await postWithSignalementsDoc.reference.update(updatedPost.toUpdateMap());
          return Result.success(updatedPost);
        }
      }

      return Result.failure(NotFoundException(
          'Aucun post correspondant trouvé ni dans la collection principale ni dans les signalements'));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> rechercheFirestore(
      String saisie, String residence) async {
    List<Post> annonceTrouvees = [];
    try {
      CollectionReference collectionReference = _firestore
          .collection("residences")
          .doc(residence)
          .collection("posts");

      QuerySnapshot querySnapshot = await collectionReference.get();

      for (var doc in querySnapshot.docs) {
        Post annonce = Post.fromMap(doc.data()! as Map<String, dynamic>);

        if ((annonce.title.toLowerCase().contains(saisie.toLowerCase())) ||
            (annonce.description.toLowerCase().contains(saisie.toLowerCase()))) {
          annonceTrouvees.add(annonce);
        }
      }
      return Result.success(annonceTrouvees);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getAllAnnoncesWithFilters({
    required String doc,
    List<String?>? subtype,
    String? dateFrom,
    String? dateTo,
    int? priceMin,
    int? priceMax,
  }) async {
    List<Post> annonces = [];
    try {
      Query<Map<String, dynamic>> baseQuery = _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
          .where('type', isEqualTo: 'annonces');

      Timestamp? timestampFrom;
      Timestamp? timestampTo;

      if (dateFrom != null && dateFrom.isNotEmpty) {
        timestampFrom = Timestamp.fromDate(DateTime.parse(dateFrom));
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        timestampTo = Timestamp.fromDate(DateTime.parse(dateTo));
      }

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

      for (var combo in combinations) {
        Query<Map<String, dynamic>> query = baseQuery;

        if (combo[0] != null) {
          query = query.where('annonce.subType', isEqualTo: combo[0]);
        }
        if (combo[1] != null) {
          query = query.where('timeStamp', isGreaterThanOrEqualTo: combo[1]);
        }
        if (combo[2] != null) {
          query = query.where('timeStamp', isLessThanOrEqualTo: combo[2]);
        }
        if (combo[3] != null) {
          query = query.where('annonce.price', isGreaterThanOrEqualTo: combo[3]);
        }
        if (combo[4] != null) {
          query = query.where('annonce.price', isLessThanOrEqualTo: combo[4]);
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
        for (var docSnapshot in querySnapshot.docs) {
          annonces.add(Post.fromMap(docSnapshot.data()));
        }
      }
      return Result.success(annonces);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getSignalementsList(
      String docRes, String postId) async {
    List<Post> signalements = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where("id", isEqualTo: postId)
          .get();

      for (var postSnapshot in querySnapshot.docs) {
        String postDocId = postSnapshot.id;

        QuerySnapshot<Map<String, dynamic>> signalementsSnapshot =
            await _firestore
                .collection("residences")
                .doc(docRes)
                .collection("posts")
                .doc(postDocId)
                .collection("signalements")
                .get();

        for (var signalementSnapshot in signalementsSnapshot.docs) {
          Post signalement = Post.fromMap(signalementSnapshot.data());
          signalements.add(signalement);
        }
      }
      return Result.success(signalements);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Post>>> getPostsByUser(
      String residenceId, String userId) async {
    List<Post> posts = [];
    try {
      QuerySnapshot postQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .where("user", isEqualTo: userId)
          .get();

      posts.addAll(postQuery.docs
          .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>)));

      QuerySnapshot allPostsQuery = await _firestore
          .collection("residences")
          .doc(residenceId)
          .collection("posts")
          .get();

      for (var postDoc in allPostsQuery.docs) {
        QuerySnapshot signalementsQuery = await postDoc.reference
            .collection("signalements")
            .where("user", isEqualTo: userId)
            .get();

        posts.addAll(signalementsQuery.docs
            .map((sig) => Post.fromMap(sig.data() as Map<String, dynamic>)));
      }

      return Result.success(posts);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Map<String, int>>> getMinMaxPrices(String doc) async {
    int priceMin = 999999999;
    int priceMax = 0;
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("residences")
          .doc(doc)
          .collection("posts")
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
      // Aucune annonce trouvée : les valeurs sentinelles ci-dessus
      // (priceMin=999999999 > priceMax=0) ne forment pas un intervalle
      // valide et font planter le RangeSlider (values.start <= values.end).
      if (priceMin > priceMax) {
        priceMin = 0;
      }
      return Result.success({'priceMin': priceMin, 'priceMax': priceMax});
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
