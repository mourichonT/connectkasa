import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

/// Lecteur vidéo réseau réutilisable (post sinistre/incivilité), basé sur
/// video_player. showControls: false pour un usage "vignette" (ex: tuile de
/// liste, jamais en lecture automatique, remplit tout le cadre en crop
/// BoxFit.cover) - true pour la lecture complète (détail du post) : tap
/// pour lecture/pause, pas de timeline ni de mode plein écran (ils
/// passaient devant les boutons like/commentaire/partager de PostView).
/// Important en mode vignette : l'appelant doit donner des contraintes
/// tight (ex: Stack(fit: StackFit.expand)), sinon ce widget se
/// redimensionnerait au ratio de la vidéo au lieu de remplir l'espace
/// disponible.
class NetworkVideoPlayer extends StatefulWidget {
  final String url;
  final bool showControls;

  const NetworkVideoPlayer({
    super.key,
    required this.url,
    this.showControls = true,
  });

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  late final VideoPlayerController _videoController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    if (widget.showControls) {
      _videoController.addListener(_onVideoUpdate);
    }
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
  }

  @override
  void dispose() {
    if (widget.showControls) {
      _videoController.removeListener(_onVideoUpdate);
    }
    // Sans cette pause, disposer le contrôleur pendant une lecture en cours
    // peut faire planter nativement le décodeur (observé sur l'émulateur
    // Android, décodeur logiciel goldfish) - laisser MediaCodec se stabiliser
    // avant de libérer la Surface.
    if (_videoController.value.isInitialized &&
        _videoController.value.isPlaying) {
      _videoController.pause();
    }
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Icon(Icons.videocam_off, color: Colors.grey, size: 40),
      );
    }
    if (!_videoController.value.isInitialized) {
      return const Center(child: AppLoader());
    }
    if (widget.showControls) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            ),
            AnimatedOpacity(
              opacity: _videoController.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController.value.size.width,
          height: _videoController.value.size.height,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }
}
