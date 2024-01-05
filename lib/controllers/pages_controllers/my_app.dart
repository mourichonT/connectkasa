import 'package:flutter/material.dart';

import '../../models/enum/tab_bar_icon.dart';
import 'my_nav_bar.dart';

class MyApp extends StatelessWidget{
  final IconTabBar iconTabBar = IconTabBar();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    List<IconData> icons = iconTabBar.listIcons();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: DefaultTabController(
            length: icons.length,
            child:MyNavBar(),
             ));
  }
}