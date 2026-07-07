import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pages_models/lot.dart';

class LoadPreferedData {
  // Scopée par uid : sans ça, le lot préféré d'un compte pouvait "fuiter"
  // vers un autre compte connecté ensuite sur le même appareil, ce qui
  // obligeait à tout effacer (clearSharedPreferences, supprimé) à chaque
  // déconnexion - avec pour effet de bord de perdre aussi la préférence
  // du même utilisateur d'une session à l'autre.
  Future<Lot?> loadPreferedLot(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lotJson = prefs.getString('preferedLot_$uid') ?? '';
    if (lotJson.isNotEmpty) {
      Map<String, dynamic> lotMap = json.decode(lotJson);
      return Lot.fromJson(lotMap);
    } else {
      return null;
    }
  }

  Future<void> savePreferedLot(String uid, Lot lot) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String lotJson = json.encode(lot.toJson());
    await prefs.setString('preferedLot_$uid', lotJson);
  }
}
