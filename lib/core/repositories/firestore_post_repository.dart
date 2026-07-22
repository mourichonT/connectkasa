import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/post.dart';

class FirestorePostRepository implements IPostRepository {
  final FirebaseFirestore _firestore;

  FirestorePostRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reconstruit un Post en imposant l'id RÉEL du document Firestore
  /// (doc.id), plutôt que de dépendre du champ "id" à l'intérieur du
  /// document lui-même (Post.fromMap retombe sur "" s'il est absent). Un
  /// document écrit hors de cette app sans ce champ (ex: konodal_bo) rendait
  /// tout post.id vide, cassant silencieusement toute relecture par id
  /// (getUpdatePost/updatePost/removePost/... filtrent tous sur
  /// where("id", isEqualTo: postId)) - jusqu'au crash chez l'appelant qui
  /// suppose la relecture toujours réussie (ex: EventWidget, "updatedPost!").
  Post _postFromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Post.fromMap({...data, 'id': doc.id});
  }

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
        return Result.success(_postFromDoc(postDoc));
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
          return Result.success(_postFromDoc(postWithSignalementsDoc));
        }
      }

      return Result.failure(NotFoundException(
          'Aucune publication trouvée avec l\'ID $postId dans la résidence $residenceId'));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removePost(String residenceId, String postId,
      {String? deletionReason}) async {
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

      DocumentSnapshot<Map<String, dynamic>> postDoc = postQuery.docs.first;

      final batch = _firestore.batch();
      if (deletionReason != null) {
        // Doc id = postId : un post ne peut avoir qu'une seule archive, un
        // nouvel appel écrase l'existante au lieu d'en empiler une seconde.
        // On archive le contenu complet du post (pas seulement la raison)
        // pour ne pas perdre son contenu à la suppression.
        final deletedPostRef = _firestore
            .collection("residences")
            .doc(residenceId)
            .collection("deletedPosts")
            .doc(postId);
        batch.set(deletedPostRef, {
          ...postDoc.data() ?? <String, dynamic>{},
          "deletionReason": deletionReason,
          "deletedAt": Timestamp.now(),
        });
      }
      batch.delete(postDoc.reference);
      await batch.commit();

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
        posts.add(_postFromDoc(docSnapshot));
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
        posts.add(_postFromDoc(docSnapshot));
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
          query = query.where('dates.creationDate', isGreaterThanOrEqualTo: combo[2]);
        }
        if (combo[3] != null) {
          query = query.where('dates.creationDate', isLessThanOrEqualTo: combo[3]);
        }
        if (combo[4] != null) {
          query = query.where('statut', isEqualTo: combo[4]);
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
        for (var docSnapshot in querySnapshot.docs) {
          posts.add(_postFromDoc(docSnapshot));
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
          .orderBy('dates.creationDate', descending: true)
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        posts.add(_postFromDoc(docSnapshot));
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
          .orderBy('dates.creationDate', descending: true)
          .get();

      for (var docSnapshot in querySnapshot.docs) {
        Post post = _postFromDoc(docSnapshot);
        posts.add(post);

        QuerySnapshot<Map<String, dynamic>> signalementsQuery =
            await docSnapshot.reference.collection("signalements").get();

        for (var signalementSnapshot in signalementsQuery.docs) {
          Post signalementPost = _postFromDoc(signalementSnapshot);
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
          .orderBy('dates.creationDate', descending: true)
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
          pageDocs.map(_postFromDoc).toList();
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
          .orderBy('dates.creationDate', descending: true)
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
        posts.add(_postFromDoc(docSnapshot));

        final signalementsQuery =
            await docSnapshot.reference.collection("signalements").get();
        for (final signalementSnapshot in signalementsQuery.docs) {
          posts.add(_postFromDoc(signalementSnapshot));
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
  Stream<List<Post>> watchAllPosts(String doc) {
    if (doc.isEmpty) return Stream.value(const []);
    return _firestore
        .collection("residences")
        .doc(doc)
        .collection("posts")
        .orderBy('dates.creationDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(_postFromDoc).toList());
  }

  @override
  Stream<List<Post>> watchAllAnnonces(String doc) {
    if (doc.isEmpty) return Stream.value(const []);
    return _firestore
        .collection("residences")
        .doc(doc)
        .collection("posts")
        .where('type', isEqualTo: 'annonces')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(_postFromDoc).toList());
  }

  @override
  Stream<PostPage> watchPostsPage(String doc, {required int limit}) {
    if (doc.isEmpty) {
      return Stream.value(
          const PostPage(posts: [], lastDocument: null, hasMore: false));
    }
    return _firestore
        .collection("residences")
        .doc(doc)
        .collection("posts")
        .orderBy('dates.creationDate', descending: true)
        .limit(limit + 1)
        .snapshots()
        .map((snapshot) {
      final hasMore = snapshot.docs.length > limit;
      final pageDocs =
          hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;
      return PostPage(
        posts: pageDocs.map(_postFromDoc).toList(),
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      );
    });
  }

  @override
  Stream<PostPage> watchPostsToModifyPage(String doc, {required int limit}) {
    if (doc.isEmpty) {
      return Stream.value(
          const PostPage(posts: [], lastDocument: null, hasMore: false));
    }
    return _firestore
        .collection("residences")
        .doc(doc)
        .collection("posts")
        .orderBy('dates.creationDate', descending: true)
        .limit(limit + 1)
        .snapshots()
        .asyncMap((snapshot) async {
      final hasMore = snapshot.docs.length > limit;
      final pageDocs =
          hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;

      // Un post -> une requête signalements, mais toutes en parallèle -
      // même motif que watchTotalCommentCount (comment_repository) : cumuler
      // ces requêtes séquentiellement se sentait sur le chargement du fil,
      // proportionnellement au nombre de posts affichés.
      final signalementsQueries = await Future.wait(pageDocs
          .map((docSnapshot) => docSnapshot.reference.collection("signalements").get()));

      final posts = <Post>[];
      for (var i = 0; i < pageDocs.length; i++) {
        posts.add(_postFromDoc(pageDocs[i]));
        posts.addAll(signalementsQueries[i].docs.map(_postFromDoc));
      }
      return PostPage(
        posts: posts,
        lastDocument: pageDocs.isNotEmpty ? pageDocs.last : null,
        hasMore: hasMore,
      );
    });
  }

  @override
  Stream<List<Post>> watchPostsByUser(String residenceId, String userId) {
    return _firestore
        .collection("residences")
        .doc(residenceId)
        .collection("posts")
        .snapshots()
        .asyncMap((snapshot) async {
      final signalementsQueries = await Future.wait(snapshot.docs.map((postDoc) =>
          postDoc.reference.collection("signalements").where("user", isEqualTo: userId).get()));

      final posts = <Post>[];
      for (var i = 0; i < snapshot.docs.length; i++) {
        final data = snapshot.docs[i].data();
        if (data['user'] == userId) {
          posts.add(_postFromDoc(snapshot.docs[i]));
        }
        posts.addAll(signalementsQueries[i].docs.map(_postFromDoc));
      }
      return posts;
    });
  }

  @override
  Future<Result<Post?>> addPost(Post newPost, String docRes) async {
    try {
      // .doc(newPost.id).set(...) et non .add(...) : .add() aurait généré
      // un id de document Firestore aléatoire, DIFFÉRENT de newPost.id (déjà
      // fixé côté client - Uuid().v1() dans post_form.dart) embarqué dans
      // toMap(). Toute relecture par id (updatePost/removePost/
      // getSignalementsList/addComment/... - où("id", ==, postId)) ne
      // retrouvait alors jamais ce post, puisque le champ "id" stocké ne
      // correspondait à aucun document réel.
      await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .doc(newPost.id)
          .set(newPost.toMap());
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
        Post post = _postFromDoc(postSnapshot);
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
          Post signalement = _postFromDoc(signalementSnapshot);
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
        return Result.success(_postFromDoc(querySnapshot.docs.first));
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
  Future<Result<void>> updatePostFields(
      String docRes, String postId, Map<String, dynamic> fields) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("residences")
          .doc(docRes)
          .collection("posts")
          .where('id', isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update(fields);
        return const Result.success(null);
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
          await signalementsQuery.docs.first.reference.update(fields);
          return const Result.success(null);
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
        Post annonce = _postFromDoc(doc);

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
          query = query.where('dates.creationDate', isGreaterThanOrEqualTo: combo[1]);
        }
        if (combo[2] != null) {
          query = query.where('dates.creationDate', isLessThanOrEqualTo: combo[2]);
        }
        if (combo[3] != null) {
          query = query.where('annonce.price', isGreaterThanOrEqualTo: combo[3]);
        }
        if (combo[4] != null) {
          query = query.where('annonce.price', isLessThanOrEqualTo: combo[4]);
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
        for (var docSnapshot in querySnapshot.docs) {
          annonces.add(_postFromDoc(docSnapshot));
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
          Post signalement = _postFromDoc(signalementSnapshot);
          signalements.add(signalement);
        }
      }
      return Result.success(signalements);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Stream<List<Post>> watchSignalementsList(
      String docRes, String postId) async* {
    if (docRes.isEmpty || postId.isEmpty) {
      yield const [];
      return;
    }
    // Résout le doc Firestore du post une seule fois (comme
    // FirestoreCommentRepository._resolvePostRef), puis flux uniquement sur
    // sa sous-collection signalements - pas besoin de réécouter la requête
    // where("id", ...) elle-même, le post ne change pas de doc Firestore.
    final postQuery = await _firestore
        .collection("residences")
        .doc(docRes)
        .collection("posts")
        .where("id", isEqualTo: postId)
        .limit(1)
        .get();
    if (postQuery.docs.isEmpty) {
      yield const [];
      return;
    }
    yield* postQuery.docs.first.reference
        .collection("signalements")
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_postFromDoc).toList());
  }

  @override
  Stream<List<String>> watchParticipants(String docRes, String postId) async* {
    if (docRes.isEmpty || postId.isEmpty) {
      yield const [];
      return;
    }
    final postQuery = await _firestore
        .collection("residences")
        .doc(docRes)
        .collection("posts")
        .where("id", isEqualTo: postId)
        .limit(1)
        .get();
    if (postQuery.docs.isEmpty) {
      yield const [];
      return;
    }
    yield* postQuery.docs.first.reference.snapshots().map((doc) =>
        (doc.data()?['participants'] as List<dynamic>? ?? [])
            .cast<String>());
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

      posts.addAll(postQuery.docs.map(_postFromDoc));

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

        posts.addAll(signalementsQuery.docs.map(_postFromDoc));
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
        var post = _postFromDoc(docSnapshot);
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
