import 'package:flutter/material.dart';
import '../../models/enum/tab_bar_icon.dart';

class MyTabBarController extends StatefulWidget {
  final IconTabBar iconTabBar = IconTabBar();

  TabBar tabBar(List<Tab> tabs) {
    return TabBar(
      padding: EdgeInsets.symmetric(horizontal: 30),
      dividerColor: Colors.transparent,
      tabs: (tabs),
      onTap: (index) {
        print(index);
      },
    );
  }

  @override
  _MyTabBarControllerState createState() => _MyTabBarControllerState();
}

class _MyTabBarControllerState extends State<MyTabBarController> {
  @override
  Widget build(BuildContext context) {
    return widget.tabBar(<Tab>[]); // Utilisez la méthode tabBar ici avec une liste vide
  }
}