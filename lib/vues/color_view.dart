import 'package:connect_kasa/controllers/features/color_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/enum/tab_bar_icon.dart';

class ColorView extends StatelessWidget {
  IconTabBar iconTabBar = IconTabBar();
  final ColorController defaultColor = ColorController();
  List<MaterialColor> colors = Colors.primaries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text("Couleur par défault: "),
              SizedBox(
                width: 20.0, // Ajustez la largeur comme nécessaire
                height: 20.0, // Ajustez la hauteur comme nécessaire
                child: Container()//mettre le cercle de couleur ici,
              ),
              const Text("Couleur choisi:"),
              SizedBox(
                width: 20.0, // Ajustez la largeur comme nécessaire
                height: 20.0, // Ajustez la hauteur comme nécessaire
                child: Container()//mettre le cercle de couleur ici,
              ),
            ],
          ),
          const Divider(),

          Expanded(
              child: GridView.builder(
                  itemCount: colors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3
                  ),
                  itemBuilder: (context, index) {
                    return Center(child: Container(),//la grille de cercle
                    );
                  }
              )
          )
        ],
      ),
    );
  }
}