import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

/// Lecture vidéo "façon Instagram" pour la carte de post du fil d'actualité :
/// remplit l'espace disponible (crop façon BoxFit.cover, pas de bandes
/// noires - la carte elle-même garde une hauteur fixe, contrainte par le
/// carrousel de doublons qui l'englobe), lecture automatique muette sans
/// timeline ni contrôles, pause automatique quand la carte sort de l'écran
/// (visibilité < 50%, sinon plusieurs vidéos liraient en même temps dans un
/// fil qui défile), et bouton "Revoir" en overlay une fois la vidéo
/// terminée (pas de bouclage automatique, et ne reprend pas tout seul en
/// revenant à l'écran - l'utilisateur doit retaper). Se place en
/// remplacement direct d'un Image.network(fit: cover) existant, sans
/// changement de layout autour.
class FeedVideoPost extends StatefulWidget {
  final String url;

  const FeedVideoPost({super.key, required this.url});

  @override
  State<FeedVideoPost> createState() => _FeedVideoPostState();
}

class _FeedVideoPostState extends State<FeedVideoPost> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _finished = false;
  bool _isVisible = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.addListener(_onVideoUpdate);
    _controller.setVolume(0);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      // Le tout premier callback de visibilité peut arriver avant la fin de
      // l'initialisation - on vérifie ici si la carte est déjà visible.
      if (_isVisible && !_finished) {
        _controller.play();
      }
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  void _onVideoUpdate() {
    if (!mounted || !_controller.value.isInitialized) return;
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final justFinished = duration > Duration.zero &&
        position >= duration &&
        !_controller.value.isPlaying;
    if (justFinished && !_finished) {
      setState(() => _finished = true);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction > 0.5;
    if (visible == _isVisible) return;
    _isVisible = visible;
    if (!_initialized || _hasError) return;

    if (visible) {
      if (!_finished) _controller.play();
    } else if (_controller.value.isPlaying) {
      _controller.pause();
    }
  }

  void _replay() {
    setState(() => _finished = false);
    _controller.seekTo(Duration.zero);
    _controller.play();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _controller.setVolume(_isMuted ? 0 : 1);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    // Sans cette pause, disposer le contrôleur pendant une lecture en cours
    // peut faire planter nativement le décodeur (cf. NetworkVideoPlayer).
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('feed-video-${widget.url}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Icon(Icons.videocam_off, color: Colors.grey, size: 40),
        ),
      );
    }
    if (!_initialized) {
      return const Center(child: AppLoader());
    }
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black45,
              ),
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        if (_finished)
          GestureDetector(
            onTap: _replay,
            child: Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay_circle_filled,
                        color: Colors.white, size: 48),
                    SizedBox(height: 6),
                    Text(
                      'Revoir',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
