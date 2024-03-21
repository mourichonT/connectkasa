import 'package:flutter/material.dart';

class ColorController extends StatefulWidget {
  const ColorController({super.key});

  @override
  ColorControllerState createState() => ColorControllerState();
}

class ColorControllerState extends State<ColorController> {
  late MaterialColor _color;
  late List<bool> selectedTabs;

  @override
  void initState() {
    super.initState();
    selectedColor("749671", 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      // Autres éléments de l'interface utilisateur ici...
    );
  }

  void selectedColor(String hexColor, int numberOfTabs) {
    setState(() {
      _color = _hexToMaterialColor(hexColor);
      selectedTabs = List.generate(numberOfTabs, (index) => index == 0);
    });
  }

  MaterialColor _hexToMaterialColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    Color color = Color(int.parse(hexColor, radix: 16));

    return MaterialColor(
      color.value,
      <int, Color>{
        50: color,
        100: color,
        200: color,
        300: color,
        400: color,
        500: color,
        600: color,
        700: color,
        800: color,
        900: color,
      },
    );
  }

  MaterialColor getColor() {
    return _color;
  }
}
