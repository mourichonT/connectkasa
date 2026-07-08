import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/core/providers/post_repository_provider.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const postsPageSize = 15;

/// Page courante d'une liste de posts paginée (Homeview, onglets de
/// SinistrePageView) : posts déjà chargés, s'il en reste à charger, et si
/// une page suivante est en cours de chargement (scroll).
class PaginatedPosts {
  final List<Post> posts;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedPosts({
    required this.posts,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  PaginatedPosts copyWith({
    List<Post>? posts,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedPosts(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Tous les posts (sinistres/incivilités/communication/annonces/événements)
/// d'une résidence, paginés (Homeview, onglet "Toutes" de SinistrePageView).
/// Ré-interroge automatiquement depuis la première page quand residenceId
/// change (nouvelle instance de famille) ;
/// ref.invalidate(postsByResidenceProvider(residenceId)) force un
/// rafraîchissement explicite (pull-to-refresh, retour de formulaire post),
/// qui revient aussi à la première page.
class PostsPaginatedNotifier extends FamilyAsyncNotifier<PaginatedPosts, String> {
  DocumentSnapshot? _lastDocument;

  @override
  Future<PaginatedPosts> build(String residenceId) async {
    _lastDocument = null;
    final repository = ref.watch(postRepositoryProvider);
    final page = await repository
        .getPostsPage(residenceId, limit: postsPageSize)
        .then((result) => result.when(
            success: (v) => v, failure: (error) => throw error));
    _lastDocument = page.lastDocument;
    return PaginatedPosts(posts: page.posts, hasMore: page.hasMore);
  }

  /// Charge la page suivante et l'ajoute à la liste déjà affichée. Appelé
  /// quand le scroll approche du bas de la liste.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final repository = ref.read(postRepositoryProvider);
    final result = await repository.getPostsPage(
      arg,
      limit: postsPageSize,
      startAfter: _lastDocument,
    );
    result.when(
      success: (page) {
        _lastDocument = page.lastDocument;
        state = AsyncData(PaginatedPosts(
          posts: [...current.posts, ...page.posts],
          hasMore: page.hasMore,
        ));
      },
      // Garde la page déjà chargée affichée ; abandonne juste le
      // "chargement en cours" pour permettre de réessayer en re-scrollant.
      failure: (_) => state = AsyncData(current.copyWith(isLoadingMore: false)),
    );
  }
}

final postsByResidenceProvider = AsyncNotifierProvider.family<
    PostsPaginatedNotifier, PaginatedPosts, String>(PostsPaginatedNotifier.new);

/// Signalements (posts reclassés par la Cloud Function de détection de
/// doublon) d'une résidence, paginés, consommés par l'onglet
/// "Mes déclarations" de SinistrePageView.
class SignalementsPaginatedNotifier
    extends FamilyAsyncNotifier<PaginatedPosts, String> {
  DocumentSnapshot? _lastDocument;

  @override
  Future<PaginatedPosts> build(String residenceId) async {
    _lastDocument = null;
    final repository = ref.watch(postRepositoryProvider);
    final page = await repository
        .getPostsToModifyPage(residenceId, limit: postsPageSize)
        .then((result) => result.when(
            success: (v) => v, failure: (error) => throw error));
    _lastDocument = page.lastDocument;
    return PaginatedPosts(posts: page.posts, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final repository = ref.read(postRepositoryProvider);
    final result = await repository.getPostsToModifyPage(
      arg,
      limit: postsPageSize,
      startAfter: _lastDocument,
    );
    result.when(
      success: (page) {
        _lastDocument = page.lastDocument;
        state = AsyncData(PaginatedPosts(
          posts: [...current.posts, ...page.posts],
          hasMore: page.hasMore,
        ));
      },
      failure: (_) => state = AsyncData(current.copyWith(isLoadingMore: false)),
    );
  }
}

final signalementsByResidenceProvider = AsyncNotifierProvider.family<
    SignalementsPaginatedNotifier, PaginatedPosts, String>(
    SignalementsPaginatedNotifier.new);

/// Tous les posts d'une résidence, SANS pagination (contrairement à
/// postsByResidenceProvider) : utilisé par EventPageView, qui a besoin de
/// l'historique complet pour construire les marqueurs du calendrier et
/// filtrer par jour sélectionné, pas d'un défilement infini.
final allPostsByResidenceProvider =
    FutureProvider.family<List<Post>, String>((ref, residenceId) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getAllPosts(residenceId).then((result) => result.when(
      success: (v) => v, failure: (error) => throw error));
});

/// Annonces d'une résidence, SANS pagination : AnnoncesPageView partage
/// cette même liste entre l'onglet "Tous" (filtré par type) et l'onglet
/// "Gérer" (filtré sur les annonces de l'utilisateur courant) - paginer
/// masquerait ses propres annonces au-delà de la première page dans
/// "Gérer" tant qu'il ne scrolle pas "Tous" jusque-là.
final annoncesByResidenceProvider =
    FutureProvider.family<List<Post>, String>((ref, residenceId) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getAllAnnonces(residenceId).then((result) => result.when(
      success: (v) => v, failure: (error) => throw error));
});
