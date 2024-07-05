import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pages_models/lot.dart';

class LoadPreferedData {
  Future<Lot?> loadPreferedLot([Lot? selectedLot]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lotJson = prefs.getString('preferedLot') ?? '';
    if (lotJson.isNotEmpty) {
      Map<String, dynamic> lotMap = json.decode(lotJson);
      return Lot.fromJson(lotMap);
    } else {
      return null;
    }
  }

  static void clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
