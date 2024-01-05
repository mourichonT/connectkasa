

import 'package:flutter/material.dart';

import '../models/lot.dart';

class LotSelectionNotifier extends ChangeNotifier {
  Lot? _selectedLot;

  Lot? get selectedLot => _selectedLot;

  void setSelectedLot(Lot lot) {
    _selectedLot = lot;
    notifyListeners();
  }
}
