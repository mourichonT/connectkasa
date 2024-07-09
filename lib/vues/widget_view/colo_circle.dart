import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ColorCircle extends StatelessWidget {
  final DataBasesLotServices databaseService = DataBasesLotServices();
  final Color color;
  final String residenceId;
  final String refLot;

  static int _tagCounter = 0;

  ColorCircle({
    required this.color,
    required this.residenceId,
    required this.refLot,
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
        context
            .read<ColorProvider>()
            .updateColor(color.value.toRadixString(16).padLeft(8, '0'));
      },
      backgroundColor: color,
      heroTag: heroTag,
    );
  }
}
