import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/colo_circle.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/color_controller.dart';
import 'package:connect_kasa/models/enum/tab_bar_icon.dart';

class ColorView extends StatefulWidget {
  final String residenceId;
  final Lot lot;
  final String refLotSelected;
  final Function(Color) onColorSelected;

  IconTabBar iconTabBar = IconTabBar();
  final ColorController defaultColor = const ColorController();
  List<Color> customColors = [
    // Rouges
    const Color.fromRGBO(204, 51, 51, 1), // Rouge profond
    const Color.fromRGBO(255, 102, 102, 1), // Rouge moyen
    const Color.fromRGBO(255, 153, 153, 1), // Rouge clair

    // Oranges
    const Color.fromRGBO(255, 153, 51, 1), // Orange profond
    const Color.fromRGBO(255, 187, 102, 1), // Orange moyen
    const Color.fromRGBO(255, 204, 153, 1), // Orange clair

    // Verts
    const Color.fromRGBO(72, 119, 91, 1), // Vert foncé (base)
    const Color.fromRGBO(102, 153, 122, 1), // Vert moyen
    const Color.fromRGBO(132, 170, 143, 1), // Vert clair
    // Bleus
    const Color.fromRGBO(0, 51, 102, 1), // Bleu foncé
    const Color.fromRGBO(51, 102, 153, 1), // Bleu moyen
    const Color.fromRGBO(102, 153, 204, 1), // Bleu clair

    // Pourpres
    const Color.fromRGBO(102, 51, 102, 1), // Pourpre foncé
    const Color.fromRGBO(153, 102, 153, 1), // Pourpre moyen
    const Color.fromRGBO(204, 153, 204, 1), // Pourpre clair

    // Roses
    const Color.fromRGBO(255, 102, 153, 1), // Rose foncé
    const Color.fromRGBO(255, 153, 187, 1), // Rose moyen
    const Color.fromRGBO(255, 204, 229, 1), // Rose clair
  ];

  ColorView({
    super.key,
    required this.residenceId,
    required this.lot,
    required this.refLotSelected,
    required this.onColorSelected,
  });

  @override
  _ColorViewState createState() => _ColorViewState();
}

class _ColorViewState extends State<ColorView> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = Color(
        int.parse(widget.lot.colorSelected.substring(2), radix: 16) +
            0xFF000000);
  }

  void _updateSelectedColor(Color newColor) {
    setState(() {
      _selectedColor = newColor;
    });
    widget.onColorSelected(newColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName('Définir une couleur pour le lot',
            Colors.black87, SizeFont.h1.size),
        // Ajoute d'autres actions d'app bar si nécessaire
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Couleur par défaut: "),
                SizedBox(
                  width: 40.0, // Ajustez la largeur comme nécessaire
                  height: 40.0, // Ajustez la hauteur comme nécessaire
                  child: ColorCircle(
                    refLotSelected: widget.refLotSelected,
                    refLot: widget.lot.refLot,
                    color: const Color.fromRGBO(72, 119, 91, 1),
                    residenceId: widget.residenceId,
                  ),
                ),
                const Text("Couleur choisie:"),
                SizedBox(
                  width: 40.0, // Ajustez la largeur comme nécessaire
                  height: 40.0, // Ajustez la hauteur comme nécessaire
                  child: Center(
                    child: ColorCircle(
                      refLotSelected: widget.refLotSelected,
                      color: _selectedColor,
                      residenceId: widget.residenceId,
                      refLot: widget.lot.refLot,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                itemCount: widget.customColors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (context, index) {
                  return Center(
                    child: ColorCircle(
                      refLotSelected: widget.refLotSelected,
                      residenceId: widget.residenceId,
                      refLot: widget.lot.refLot,
                      color: widget.customColors[index],
                      onColorSelected: _updateSelectedColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
