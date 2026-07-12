import 'package:konodal/controllers/providers/color_provider.dart';
import 'package:konodal/models/enum/set_gif_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Loader animé (GIF) utilisé partout dans l'app à la place de
/// CircularProgressIndicator. Suit la couleur du lot sélectionné, comme
/// le logo (SetLogoColor.getLogoPath) le fait déjà.
class AppLoader extends StatelessWidget {
  final double size;

  /// Couleur explicite à utiliser à la place de celle du lot actif
  /// (ColorProvider). Utile sur les écrans affichés avant qu'un lot ne
  /// soit connu (connexion, transition post-authentification) où le
  /// ColorProvider peut encore contenir la couleur d'un lot précédent.
  final Color? color;

  const AppLoader({super.key, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? context.watch<ColorProvider>().color;
    return Image.asset(
      SetGifColor.getGifPath(activeColor),
      width: size,
      height: size,
      // Le GIF n'est pas carré (401x494) : sans fit explicite,
      // Image.asset l'étire pour remplir exactement width/height,
      // déformant le logo de façon non uniforme. contain préserve le
      // ratio d'origine.
      fit: BoxFit.contain,
    );
  }
}
