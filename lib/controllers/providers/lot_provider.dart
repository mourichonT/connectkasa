import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class LotProvider with ChangeNotifier {
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();
  final LoadPreferedData _loadPreferedData = LoadPreferedData();

  Lot? _currentLot;
  Lot? get currentLot => _currentLot;

  Future<void> loadLot(String uid) async {
    Lot? prefered = await _loadPreferedData.loadPreferedLot();
    _currentLot =
        prefered ?? await _databasesLotServices.getFirstLotByUserId(uid);
    notifyListeners();
  }

  void setLot(Lot lot) {
    _currentLot = lot;
    notifyListeners();
  }
}
