import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ColorCircle extends StatelessWidget {
  final DataBasesLotServices databaseService = DataBasesLotServices();
  final Color color;
  final String userId;
  final String refLot;
  final String refLotSelected;
  final Function(Color)? onColorSelected;

  static int _tagCounter = 0;

  ColorCircle({
    super.key,
    required this.color,
    required this.userId,
    required this.refLot,
    required this.refLotSelected,
    this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    _tagCounter++;
    String heroTag = '${color.toString()}_$_tagCounter';

    return FloatingActionButton(
      onPressed: () async {
        // 1. Mettre à jour dans Firebase
        await databaseService.updateLotColor(userId, refLot, color);

        // 2. Mettre à jour dans ColorProvider si c'est le bon lot
        if (refLot == refLotSelected) {
          final hexColor = color.value.toRadixString(16).padLeft(8, '0');
          context.read<ColorProvider>().updateColor(hexColor);

          // 3. Mettre à jour dans SharedPreferences
          final loadService = LoadPreferedData();
          Lot? currentLot = await loadService.loadPreferedLot();
          if (currentLot != null && currentLot.refLot == refLotSelected) {
            currentLot.userLotDetails['colorSelected'] = hexColor;
            await loadService.savePreferedLot(currentLot);
          }
        }

        // 4. Callback au parent
        if (onColorSelected != null) {
          onColorSelected!(color);
        }
      },
      backgroundColor: color,
      heroTag: heroTag,
    );
  }
}
