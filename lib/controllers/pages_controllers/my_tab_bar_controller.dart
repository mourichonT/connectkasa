import 'package:flutter/material.dart';
import '../../models/enum/tab_bar_icon.dart';

class MyTabBarController {
  final IconTabBar iconTabBar = IconTabBar();
  late TabController tabController;

  MyTabBarController({required int length, required vsync}) {
    tabController = TabController(length: length, vsync: vsync);
  }

  TabBar tabBar(List<Tab> tabs) {
    return TabBar(
      controller: tabController,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      dividerColor: Colors.transparent,
      tabs: tabs,
      onTap: (index) {
        print(index);
      },
    );
  }

  void dispose() {
    tabController.dispose();
  }
}

class MyTabBarWidget extends StatefulWidget {
  final MyTabBarController controller;

  const MyTabBarWidget({super.key, required this.controller});

  @override
  _MyTabBarWidgetState createState() => _MyTabBarWidgetState();
}

class _MyTabBarWidgetState extends State<MyTabBarWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> icons =
        widget.controller.iconTabBar.listIcons();
    final List<Tab> tabs = icons
        .map((iconData) => Tab(
              icon: Icon(
                iconData['icon'],
                size: iconData['size'], // Utilisation de la taille spécifique
              ),
            ))
        .toList();

    return widget.controller.tabBar(tabs);
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
