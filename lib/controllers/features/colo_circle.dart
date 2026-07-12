import 'package:konodal/controllers/features/load_prefered_data.dart';
import 'package:konodal/controllers/providers/color_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ColorCircle extends StatelessWidget {
  final ILotRepository databaseService = FirestoreLotRepository();
  final Color color;
  final String userId;
  final String idLot;
  final String idLotSelected;
  final Function(Color)? onColorSelected;

  static int _tagCounter = 0;

  ColorCircle({
    super.key,
    required this.color,
    required this.userId,
    required this.idLot,
    required this.idLotSelected,
    this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    _tagCounter++;
    String heroTag = '${color.toString()}_$_tagCounter';

    return FloatingActionButton(
      onPressed: () async {
        // 1. Mettre à jour dans Firebase
        await databaseService.updateLotColor(userId, idLot, color);
        if (!context.mounted) return;

        // 2. Mettre à jour dans ColorProvider si c'est le bon lot
        if (idLot == idLotSelected) {
          final hexColor = color.toARGB32().toRadixString(16).padLeft(8, '0');
          context.read<ColorProvider>().updateColor(hexColor);

          // 3. Mettre à jour dans SharedPreferences
          final loadService = LoadPreferedData();
          Lot? currentLot = await loadService.loadPreferedLot(userId);
          if (currentLot != null && currentLot.id == idLotSelected) {
            currentLot.userLotDetails['colorSelected'] = hexColor;
            await loadService.savePreferedLot(userId, currentLot);
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
