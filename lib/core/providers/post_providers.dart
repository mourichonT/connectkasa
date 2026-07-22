import 'dart:async';

import 'package:konodal/core/providers/post_repository_provider.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/models/pages_models/post.dart';
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
/// Contrairement à un simple StreamProvider, la fenêtre affichée (limit)
/// grandit à chaque loadMore() plutôt que de dépendre d'un curseur
/// startAfter : chaque post déjà affiché reste sur un flux temps réel
/// (.snapshots()), donc une modification/suppression/ajout dans la fenêtre
/// déjà chargée se répercute immédiatement, sans attendre un refetch.
/// ref.invalidate(postsByResidenceProvider(residenceId)) revient à la
/// première page (pull-to-refresh, retour de formulaire post).
class PostsPaginatedNotifier extends FamilyAsyncNotifier<PaginatedPosts, String> {
  int _limit = postsPageSize;
  StreamSubscription<PostPage>? _subscription;

  @override
  Future<PaginatedPosts> build(String residenceId) async {
    _limit = postsPageSize;
    final repository = ref.watch(postRepositoryProvider);
    ref.onDispose(() => _subscription?.cancel());
    return _subscribe(repository, residenceId);
  }

  Future<PaginatedPosts> _subscribe(
      IPostRepository repository, String residenceId) {
    final completer = Completer<PaginatedPosts>();
    _subscription?.cancel();
    _subscription =
        repository.watchPostsPage(residenceId, limit: _limit).listen(
      (page) {
        final data = PaginatedPosts(posts: page.posts, hasMore: page.hasMore);
        if (!completer.isCompleted) {
          completer.complete(data);
        } else {
          state = AsyncData(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        } else {
          state = AsyncError(error, stackTrace);
        }
      },
    );
    return completer.future;
  }

  /// Élargit la fenêtre affichée. Appelé quand le scroll approche du bas de
  /// la liste.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    _limit += postsPageSize;
    final repository = ref.read(postRepositoryProvider);
    try {
      final data = await _subscribe(repository, arg);
      state = AsyncData(data);
    } catch (_) {
      // Garde la page déjà chargée affichée ; abandonne juste le
      // "chargement en cours" pour permettre de réessayer en re-scrollant.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final postsByResidenceProvider = AsyncNotifierProvider.family<
    PostsPaginatedNotifier, PaginatedPosts, String>(PostsPaginatedNotifier.new);

/// Signalements (posts reclassés par la Cloud Function de détection de
/// doublon) d'une résidence, paginés, consommés par l'onglet
/// "Mes déclarations" de SinistrePageView. Même principe temps réel que
/// PostsPaginatedNotifier ci-dessus.
class SignalementsPaginatedNotifier
    extends FamilyAsyncNotifier<PaginatedPosts, String> {
  int _limit = postsPageSize;
  StreamSubscription<PostPage>? _subscription;

  @override
  Future<PaginatedPosts> build(String residenceId) async {
    _limit = postsPageSize;
    final repository = ref.watch(postRepositoryProvider);
    ref.onDispose(() => _subscription?.cancel());
    return _subscribe(repository, residenceId);
  }

  Future<PaginatedPosts> _subscribe(
      IPostRepository repository, String residenceId) {
    final completer = Completer<PaginatedPosts>();
    _subscription?.cancel();
    _subscription =
        repository.watchPostsToModifyPage(residenceId, limit: _limit).listen(
      (page) {
        final data = PaginatedPosts(posts: page.posts, hasMore: page.hasMore);
        if (!completer.isCompleted) {
          completer.complete(data);
        } else {
          state = AsyncData(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        } else {
          state = AsyncError(error, stackTrace);
        }
      },
    );
    return completer.future;
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    _limit += postsPageSize;
    final repository = ref.read(postRepositoryProvider);
    try {
      final data = await _subscribe(repository, arg);
      state = AsyncData(data);
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final signalementsByResidenceProvider = AsyncNotifierProvider.family<
    SignalementsPaginatedNotifier, PaginatedPosts, String>(
    SignalementsPaginatedNotifier.new);

/// Tous les posts d'une résidence, SANS pagination (contrairement à
/// postsByResidenceProvider) : utilisé par EventPageView, qui a besoin de
/// l'historique complet pour construire les marqueurs du calendrier et
/// filtrer par jour sélectionné, pas d'un défilement infini. Temps réel.
final allPostsByResidenceProvider =
    StreamProvider.family<List<Post>, String>((ref, residenceId) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.watchAllPosts(residenceId);
});

/// Annonces d'une résidence, SANS pagination : AnnoncesPageView partage
/// cette même liste entre l'onglet "Tous" (filtré par type) et l'onglet
/// "Gérer" (filtré sur les annonces de l'utilisateur courant) - paginer
/// masquerait ses propres annonces au-delà de la première page dans
/// "Gérer" tant qu'il ne scrolle pas "Tous" jusque-là. Temps réel.
final annoncesByResidenceProvider =
    StreamProvider.family<List<Post>, String>((ref, residenceId) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.watchAllAnnonces(residenceId);
});

/// Publications d'un utilisateur donné dans une résidence (ShowProfilPage) :
/// une seule requête partagée par les 3 onglets (déclarations/annonces/
/// événements), qui filtrent ensuite côté client par type - au lieu de
/// relancer la même requête à chaque changement d'onglet. Temps réel.
final userPostsByResidenceProvider = StreamProvider.family<List<Post>,
    ({String residenceId, String userId})>((ref, args) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.watchPostsByUser(args.residenceId, args.userId);
});

/// Participants d'un événement (uids), en temps réel - PartipedTile
/// (EventWidget Homeview ET EventPageDetails) partageaient chacun une copie
/// locale figée à l'ouverture de l'écran (initState) : participer sur l'un
/// ne se reflétait jamais sur l'autre sans redémarrer l'app.
final participantsProvider = StreamProvider.family<List<String>,
    ({String residenceId, String postId})>((ref, args) {
  final repository = ref.watch(postRepositoryProvider);
  return repository.watchParticipants(args.residenceId, args.postId);
});
