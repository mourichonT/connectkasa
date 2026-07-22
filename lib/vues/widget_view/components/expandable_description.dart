import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

/// Description de post tronquée à [collapsedMaxLines] lignes avec une
/// bascule "Voir plus"/"Voir moins" - affichée seulement si le texte
/// dépasse réellement ce nombre de lignes à la largeur disponible (mesuré
/// via TextPainter, pas une estimation sur la longueur de la chaîne).
/// Partagé entre EventWidget et SignalementTile, dont les descriptions
/// étaient chacune tronquées à un nombre de lignes fixe sans aucun moyen
/// de les lire en entier.
class ExpandableDescription extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int collapsedMaxLines;

  const ExpandableDescription({
    super.key,
    required this.text,
    required this.style,
    this.collapsedMaxLines = 5,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.collapsedMaxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.collapsedMaxLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MyTextStyle.postDesc(
                      _expanded ? "Voir moins" : "Voir plus",
                      SizeFont.para.size,
                      Colors.black54,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
