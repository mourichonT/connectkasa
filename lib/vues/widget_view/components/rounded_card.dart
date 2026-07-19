import 'package:flutter/material.dart';

/// Carte à bords arrondis, sans bordure (juste un léger shadow pour la
/// détacher du fond - style "imbriqué" des maquettes dashboard, plus de
/// gros drop-shadow gris à angles droits). ClipRRect (pas seulement le
/// BorderRadius du Container) est nécessaire
/// pour que le contenu plein-large (image, bandeau...) soit lui aussi
/// rogné aux angles arrondis, plutôt que de déborder en angle droit
/// par-dessus la bordure.
class RoundedCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const RoundedCard({super.key, required this.child, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    // Le shadow doit être porté par un Container SANS ClipRRect autour :
    // une ombre se dessine hors des bords de la box, donc un ClipRRect
    // englobant la couperait entièrement. Le ClipRRect ne sert qu'à rogner
    // le contenu interne (image, bandeau...) aux angles arrondis.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        // Un seul arrondi (porté par ce ClipRRect) : lui donner AUSSI un
        // borderRadius sur la décoration du Container blanc ci-dessous
        // duplique l'arrondi via deux opérations de rendu différentes
        // (clip vs remplissage) censées coïncider au pixel près mais qui
        // peuvent légèrement diverger - source probable du liseré observé
        // sur les bords droite/bas de la carte pub.
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          color: Colors.white,
          child: child,
        ),
      ),
    );
  }
}
