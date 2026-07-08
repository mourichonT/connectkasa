import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/post.dart';

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
