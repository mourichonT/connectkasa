import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/residence.dart';

/// Logique de requêtes en cascade (type de bien -> bâtiment -> numéro)
/// partagée entre Step3 (sélection du lot principal) et le sélecteur de lot
/// enfant (child_lot_picker_sheet.dart). Extraite de _Step3State pour
/// pouvoir la réutiliser dans un contexte non lié au PageView/
/// progressController de Step3, avec un filtre optionnel (ex: isLinkable).
class LotCascadeHelper {
  static Future<List<Lot>> _lotsOfResidence(
      ILotRepository repo, Residence residence) {
    return repo
        .getLotByResidence(residence.id)
        .then((result) => result.when(success: (v) => v, failure: (_) => <Lot>[]));
  }

  static Future<List<String>> typeLots(
      ILotRepository repo, Residence residence, {bool Function(Lot)? filter}) async {
    final lots = await _lotsOfResidence(repo, residence);
    final types = <String>{};
    for (final lot in lots) {
      if (filter == null || filter(lot)) {
        types.add(lot.typeLot);
      }
    }
    return types.toList();
  }

  static Future<List<String>> batiments(
      ILotRepository repo, Residence residence, String typeChoice,
      {bool Function(Lot)? filter}) async {
    final lots = await _lotsOfResidence(repo, residence);
    final batimentsUniques = <String>{};
    for (final lot in lots) {
      if (lot.typeLot == typeChoice &&
          lot.batiment != null &&
          (filter == null || filter(lot))) {
        batimentsUniques.add(lot.batiment!);
      }
    }
    return batimentsUniques.toList();
  }

  static Future<List<String>> numeros(
      ILotRepository repo, Residence residence, String typeChoice,
      [String? batiment, bool Function(Lot)? filter]) async {
    final lots = await _lotsOfResidence(repo, residence);
    final lotsUniques = <String>{};
    for (final lot in lots) {
      if (lot.typeLot == typeChoice &&
          lot.lot != null &&
          (batiment == null || lot.batiment == batiment) &&
          (filter == null || filter(lot))) {
        lotsUniques.add(lot.lot!);
      }
    }
    return lotsUniques.toList();
  }

  static Future<Lot?> resolveLot(
      ILotRepository repo, String residenceId, String bat, String numLot) {
    return repo
        .getUniqueLot(residenceId, bat, numLot)
        .then((result) => result.when(success: (v) => v, failure: (_) => null));
  }
}
