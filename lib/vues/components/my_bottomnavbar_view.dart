import 'package:flutter/material.dart';
import '../../controllers/features/my_bottomnavbar_ controller.dart';


class MyBottomNavBarView extends StatelessWidget {
  final MyBottomNavBarController bottomNavBarController = MyBottomNavBarController();

  @override
  Widget build(BuildContext context) {
    // Récupérez les icônes à ce niveau
    List<List<dynamic>> icons = bottomNavBarController.iconTabBar.listIconsBottom();

    // Créez les onglets de la barre de navigation avec la couleur du thème
    List<BottomNavigationBarItem> bottomTabs = icons.asMap().entries.map((entry) {
      int bottomIndex = entry.key;
      IconData icon = entry.value[0];
      String label = entry.value[1];
      return BottomNavigationBarItem(
        icon: Icon(
          icon,
          color: Theme.of(context).iconTheme.color,
        ),
        label: label,
      );
    }).toList();

    return Container(
            color: Colors.blue, // Vous pouvez définir la couleur de fond de la BottomNavBar ici
            child: Row(
              children: [
                Expanded(
                  child: MyBottomNavBarController().bottomNavBar(bottomTabs, context),
                ),
              ],
            ),
          );
  }
}