import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/post.dart';

/// Une page de résultats pour les listes de posts paginées (Homeview,
/// SinistrePageView) : les posts de cette page, le curseur Firestore à
/// passer en startAfter pour la page suivante (null si plus rien à charger
/// après cette page), et hasMore pour savoir s'il faut proposer de charger
/// la suite.
class PostPage {
  final List<Post> posts;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PostPage({
    required this.posts,
    required this.lastDocument,
    required this.hasMore,
  });
}

/// Remplace DataBasesPostServices (Phase 2 du chantier architecture).
abstract interface class IPostRepository {
  Future<Result<Post>> getPost(String residenceId, String postId);

  Future<Result<void>> removePost(String residenceId, String postId);

  Future<Result<List<Post>>> getAllAnnonces(String doc);

  Future<Result<List<Post>>> getAnnonceById(String doc, String uid);

  Future<Result<List<Post>>> getAllPostsWithFilters({
    required String doc,
    List<String?>? locationElement,
    List<String?>? type,
    String? dateFrom,
    String? dateTo,
    List<String?>? statut,
  });

  Future<Result<List<Post>>> getAllPosts(String doc);

  Future<Result<List<Post>>> getAllPostsToModify(String doc);

  /// Variante paginée de getAllPosts, pour Homeview et l'onglet "Toutes"
  /// de SinistrePageView (chargement au scroll).
  Future<Result<PostPage>> getPostsPage(
    String doc, {
    required int limit,
    DocumentSnapshot? startAfter,
  });

  /// Variante paginée de getAllPostsToModify, pour l'onglet "Mes
  /// déclarations" de SinistrePageView.
  Future<Result<PostPage>> getPostsToModifyPage(
    String doc, {
    required int limit,
    DocumentSnapshot? startAfter,
  });

  Future<Result<Post?>> addPost(Post newPost, String docRes);

  Future<Result<Post?>> addSignalement(
      Post newSignalement, String docRes, String idPost);

  Future<Result<void>> updatePostLikes(
      String residenceId, String postId, String userId);

  Future<Result<void>> removePostLike(
      String residenceId, String postId, String userId);

  Future<Result<List<Post>>> getSignalements(String docRes, String postId);

  Future<Result<Post?>> getUpdatePost(String docRes, String postId);

  Future<Result<void>> updatePostParticipants(
      String residenceId, String postId, String userId);

  Future<Result<void>> removePostParticipants(
      String residenceId, String postId, String userId);

  Future<Result<Post?>> updatePost(
      Post updatedPost, String docRes, String postId);

  Future<Result<List<Post>>> rechercheFirestore(
      String saisie, String residence);

  Future<Result<List<Post>>> getAllAnnoncesWithFilters({
    required String doc,
    List<String?>? subtype,
    String? dateFrom,
    String? dateTo,
    int? priceMin,
    int? priceMax,
  });

  Future<Result<List<Post>>> getSignalementsList(String docRes, String postId);

  Future<Result<List<Post>>> getPostsByUser(
      String residenceId, String userId);

  Future<Result<Map<String, int>>> getMinMaxPrices(String doc);
}
