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

  /// Si [deletionReason] est fourni, le post est archivé (contenu complet +
  /// raison + date/heure de suppression) dans un document unique
  /// (residences/{residenceId}/deletedPosts/{postId}) avant d'être effacé de
  /// "posts". L'id du document est le postId : un nouvel appel écrase
  /// l'archive existante plutôt que d'en créer une seconde.
  Future<Result<void>> removePost(String residenceId, String postId,
      {String? deletionReason});

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

  /// Équivalent temps réel de getPostsPage : pas de startAfter, la fenêtre
  /// affichée grandit simplement (limit croissant) à chaque loadMore(), et
  /// se met à jour automatiquement si un post de la fenêtre change/est
  /// ajouté/supprimé.
  Stream<PostPage> watchPostsPage(String doc, {required int limit});

  /// Équivalent temps réel de getPostsToModifyPage.
  Stream<PostPage> watchPostsToModifyPage(String doc, {required int limit});

  /// Équivalent temps réel de getAllPosts.
  Stream<List<Post>> watchAllPosts(String doc);

  /// Équivalent temps réel de getAllAnnonces.
  Stream<List<Post>> watchAllAnnonces(String doc);

  /// Équivalent temps réel de getPostsByUser.
  Stream<List<Post>> watchPostsByUser(String residenceId, String userId);

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

  /// Mise à jour ciblée d'un sous-ensemble de champs, sans passer par un
  /// objet Post complet (ex: dateClosed, écrit uniquement au moment précis
  /// où un sinistre passe en "Terminé" - pas modélisé sur Post pour éviter
  /// tout risque qu'un autre appel à updatePost() l'efface silencieusement).
  Future<Result<void>> updatePostFields(
      String docRes, String postId, Map<String, dynamic> fields);

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

  /// Équivalent temps réel de getSignalementsList - PostWidget (carrousel de
  /// doublons sur Homeview) y était abonné via une simple Future, jamais
  /// rafraîchie après le premier chargement de la carte : un signalement
  /// détecté pendant que la carte est déjà affichée n'apparaissait donc
  /// jamais sans quitter/revenir sur Homeview.
  Stream<List<Post>> watchSignalementsList(String docRes, String postId);

  Future<Result<List<Post>>> getPostsByUser(
      String residenceId, String userId);

  Future<Result<Map<String, int>>> getMinMaxPrices(String doc);
}
