import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/core/repositories/lot_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_lot_repository.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class LotProvider with ChangeNotifier {
  final ILotRepository _databasesLotServices = FirestoreLotRepository();
  final LoadPreferedData _loadPreferedData = LoadPreferedData();

  Lot? _currentLot;
  Lot? get currentLot => _currentLot;

  Future<void> loadLot(String uid) async {
    Lot? prefered = await _loadPreferedData.loadPreferedLot(uid);
    _currentLot = prefered ??
        await _databasesLotServices.getFirstLotByUserId(uid).then((result) =>
            result.when(success: (v) => v, failure: (error) => throw error));
    notifyListeners();
  }

  void setLot(Lot lot) {
    _currentLot = lot;
    notifyListeners();
  }
}
