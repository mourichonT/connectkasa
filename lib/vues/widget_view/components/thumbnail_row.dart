import 'package:flutter/material.dart';
import 'package:konodal/vues/widget_view/components/fullscreen_image_view.dart';

/// Affichage en lecture seule des vignettes secondaires d'une annonce
/// (Post.thumbnails, max 3) - sous la description, cf. ThumbnailPicker pour
/// la sélection côté formulaire. Un tap ouvre l'image en plein écran.
class ThumbnailRow extends StatelessWidget {
  final List<String> thumbnails;
  final double size;

  const ThumbnailRow({super.key, required this.thumbnails, this.size = 70});

  @override
  Widget build(BuildContext context) {
    if (thumbnails.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final url in thumbnails)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FullScreenImageView(imageUrl: url),
              )),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
