// ignore_for_file: use_key_in_widget_constructors, file_names

import 'package:connect_kasa/controllers/features/route_controller.dart';
import 'package:connect_kasa/vues/pages_vues/contact_view.dart';
import 'package:flutter/material.dart';
import '../../models/enum/tab_bar_icon.dart';

class MyBottomNavBarController extends StatefulWidget {
  final String residenceSelected;
  final String residenceName;

  final IconTabBar iconTabBar = IconTabBar();

  MyBottomNavBarController(
      {Key? key, required this.residenceSelected, required this.residenceName});

  @override
  State<StatefulWidget> createState() => MyBottomNavBarState();

  BottomNavigationBar bottomNavBar(
      List<BottomNavigationBarItem> bottomTabs, BuildContext context) {
    return BottomNavigationBar(
      fixedColor: Colors.black54,
      unselectedItemColor: Colors.black54,
      items: bottomTabs,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).push(RouteController().createRoute(
              ContactView(
                residenceSelected: residenceSelected,
                residenceName: residenceName,
              ),
            ));

            break;
          case 1:
            print("message");
            break;
        }
      },
      selectedIconTheme: Theme.of(context).iconTheme,
    );
  }
}

class MyBottomNavBarState extends State<MyBottomNavBarController> {
  @override
  Widget build(BuildContext context) {
    return widget.bottomNavBar(<BottomNavigationBarItem>[], context);
  }
}
