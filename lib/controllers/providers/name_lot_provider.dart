import 'package:flutter/material.dart';
import 'package:konodal/core/utils/app_logger.dart';

class NameLotProvider with ChangeNotifier {
  String _name = '';

  String get name => _name;

  // Permet d'initialiser le name au démarrage
  void initializeName(String initialName) {
    _name = initialName;
    appLog("PROVIDERNAME in initializeName/ $_name");
    notifyListeners();
  }

  // Permet de mettre à jour dynamiquement
  void updateNameLot(String newName) {
    _name = newName;
    appLog("PROVIDERNAME in updateNameLot/ $_name");
    notifyListeners();
  }
}
