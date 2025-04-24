import 'package:flutter/material.dart';

class ColorProvider with ChangeNotifier {
  Color _color = const Color.fromRGBO(72, 119, 91, 1); // Couleur par défaut

  Color get color => _color;

  void updateColor(String colorHex) {
    _color = Color(int.parse(colorHex.substring(2), radix: 16) + 0xFF000000);
    notifyListeners();
  }
}
