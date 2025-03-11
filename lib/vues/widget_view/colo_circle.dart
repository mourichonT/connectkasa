import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ColorCircle extends StatelessWidget {
  final DataBasesLotServices databaseService = DataBasesLotServices();
  final Color color;
  final String residenceId;
  final String refLot;
  final String refLotSelected;
  final Function(Color)? onColorSelected;

  static int _tagCounter = 0;

  ColorCircle({super.key, 
    required this.color,
    required this.residenceId,
    required this.refLot,
    required this.refLotSelected,
    this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    _tagCounter++;
    String heroTag = '${color.toString()}_$_tagCounter';

    return FloatingActionButton(
      onPressed: () {
        // Mettre à jour la couleur dans la base de données
        databaseService.updateLotColor(residenceId, refLot, color);
        // Mettre à jour la couleur dans ColorProvider
        if (refLot == refLotSelected) {
          context
              .read<ColorProvider>()
              .updateColor(color.value.toRadixString(16).padLeft(8, '0'));
        }
        // Appeler le callback pour notifier le parent
        if (onColorSelected != null) {
          onColorSelected!(color);
        }
      },
      backgroundColor: color,
      heroTag: heroTag,
    );
  }
}
