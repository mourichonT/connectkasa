import 'package:flutter/material.dart';
import '../../models/enum/tab_bar_icon.dart';

class MyBottomNavBarController extends StatefulWidget {
  final IconTabBar iconTabBar = IconTabBar();

  @override
  State<StatefulWidget> createState() => MyBottomNavBarState();

  BottomNavigationBar bottomNavBar(List<BottomNavigationBarItem> bottomTabs, BuildContext context) {
    return BottomNavigationBar(
      items: bottomTabs,
      onTap: (index) {
        print(index);
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
