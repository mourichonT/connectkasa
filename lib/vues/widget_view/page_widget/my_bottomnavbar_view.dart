// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:connect_kasa/controllers/pages_controllers/my_bottomnavbar_%20controller.dart';
import 'package:connect_kasa/controllers/providers/message_provider.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      IconData icon = entry.value[0];
      String label = entry.value[1];

      // Ajouter la pastille uniquement sur l'icône de message
      if (icon == Icons.messenger_outline) {
        return BottomNavigationBarItem(
          icon: StreamBuilder<bool>(
            stream: context.read<MessageProvider>().hasNewMessageStream,
            builder: (context, snapshot) {
              final hasNewMessage = snapshot.data ?? false;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: Colors.black54),
                  if (hasNewMessage)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: label,
        );
      } else {
        return BottomNavigationBarItem(
          icon: Icon(icon, color: Colors.black54),
          label: label,
        );
      }
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
