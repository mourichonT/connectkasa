import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/providers/name_lot_provider.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';

class LotProvider with ChangeNotifier {
  late Lot _lot;

  Lot get lot => _lot;

  LotProvider(ColorProvider colorProvider, NameLotProvider nameLotProvider) {
    _lot = Lot(
      refLot: "",
      typeLot: "",
      type: "",
      idProprietaire: [],
      idLocataire: [],
      residenceId: "",
      residenceData: {},
      userLotDetails: {},
    );

    // Initialiser les valeurs du lot avec les données des providers
    _lot.userLotDetails['colorSelected'] =
        colorProvider.color.value.toRadixString(16);
    _lot.userLotDetails['nameLot'] = nameLotProvider.name;

    // Ajout des listeners pour les changements
    colorProvider.addListener(_updateLot);
    nameLotProvider.addListener(_updateLot);
  }

  // Fonction de mise à jour du lot quand les providers changent
  void _updateLot() {
    _lot = Lot(
      refLot: _lot.refLot,
      typeLot: _lot.typeLot,
      type: _lot.type,
      idProprietaire: _lot.idProprietaire,
      idLocataire: _lot.idLocataire,
      residenceId: _lot.residenceId,
      residenceData: {},
      userLotDetails: {
        'colorSelected': _lot.userLotDetails['colorSelected'],
        'nameLot': _lot.userLotDetails['nameLot'],
      },
    );

    print("LOT MIS A JOUR / ${_lot.userLotDetails['nameLot']}");
    notifyListeners(); // Notifie les listeners lorsque le lot est mis à jour
  }

  // Méthode publique pour appeler la mise à jour du lot
  void updateLotFromProviders() {
    _updateLot();
  }
}
