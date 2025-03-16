// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:connect_kasa/controllers/pages_controllers/my_bottomnavbar_%20controller.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class MyBottomNavBarView extends StatelessWidget {
  final String residenceSelected;
  final String residenceName;
  final String uid;
  final Lot selectedLot;

  MyBottomNavBarView({
    super.key,
    required this.residenceSelected,
    required this.residenceName,
    required this.uid,
    required this.selectedLot,
  });

  @override
  Widget build(BuildContext context) {
    final MyBottomNavBarController bottomNavBarController =
        MyBottomNavBarController(
      residenceSelected: residenceSelected,
      residenceName: residenceName,
      uid: uid,
      selectedLot: selectedLot,
    );
    // Récupérez les icônes à ce niveau
    List<List<dynamic>> icons =
        bottomNavBarController.iconTabBar.listIconsBottom();

    // Créez les onglets de la barre de navigation avec la couleur du thème
    List<BottomNavigationBarItem> bottomTabs =
        icons.asMap().entries.map((entry) {
      // int bottomIndex = entry.key;
      IconData icon = entry.value[0];
      String label = entry.value[1];
      return BottomNavigationBarItem(
        icon: Icon(
          icon,
          color: Colors.black54,
        ),
        label: label,
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: bottomNavBarController.bottomNavBar(
            bottomTabs,
            context,
          ), // Correction : Passer un index initial (0 dans cet exemple)
        ),
      ],
    );
  }
}
