import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/colo_circle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_kasa/controllers/features/color_controller.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/models/enum/tab_bar_icon.dart';

class ColorView extends StatelessWidget {
  IconTabBar iconTabBar = IconTabBar();
  final String residenceId;
  final String refLot;
  final ColorController defaultColor = const ColorController();
  List<Color> customColors = [
    // Rouges
    Color.fromRGBO(204, 51, 51, 1), // Rouge profond
    Color.fromRGBO(255, 102, 102, 1), // Rouge moyen
    Color.fromRGBO(255, 153, 153, 1), // Rouge clair

    // Oranges
    Color.fromRGBO(255, 153, 51, 1), // Orange profond
    Color.fromRGBO(255, 187, 102, 1), // Orange moyen
    Color.fromRGBO(255, 204, 153, 1), // Orange clair

    // Verts
    Color.fromRGBO(72, 119, 91, 1), // Vert foncé (base)
    Color.fromRGBO(102, 153, 122, 1), // Vert moyen
    Color.fromRGBO(132, 170, 143, 1), // Vert clair
    // Bleus
    Color.fromRGBO(0, 51, 102, 1), // Bleu foncé
    Color.fromRGBO(51, 102, 153, 1), // Bleu moyen
    Color.fromRGBO(102, 153, 204, 1), // Bleu clair

    // Pourpres
    Color.fromRGBO(102, 51, 102, 1), // Pourpre foncé
    Color.fromRGBO(153, 102, 153, 1), // Pourpre moyen
    Color.fromRGBO(204, 153, 204, 1), // Pourpre clair

    // Roses
    Color.fromRGBO(255, 102, 153, 1), // Rose foncé
    Color.fromRGBO(255, 153, 187, 1), // Rose moyen
    Color.fromRGBO(255, 204, 229, 1), // Rose clair
  ];

  ColorView({super.key, required this.residenceId, required this.refLot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName('Définir une couloeur pour le lot',
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
                    color: const Color.fromRGBO(72, 119, 91, 1),
                    residenceId: residenceId,
                    refLot: refLot,
                  ),
                ),
                const Text("Couleur choisie:"),
                SizedBox(
                  width: 40.0, // Ajustez la largeur comme nécessaire
                  height: 40.0, // Ajustez la hauteur comme nécessaire
                  child: Center(
                    child: ColorCircle(
                      color: context.watch<ColorProvider>().color,
                      residenceId: residenceId,
                      refLot: refLot,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                itemCount: customColors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (context, index) {
                  return Center(
                    child: ColorCircle(
                      residenceId: residenceId,
                      refLot: refLot,
                      color: customColors[index],
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
