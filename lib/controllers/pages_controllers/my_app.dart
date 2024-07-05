import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/enum/tab_bar_icon.dart';
import '../../vues/pages_vues/my_nav_bar.dart';

class MyApp extends StatelessWidget {
  final IconTabBar iconTabBar = IconTabBar();
  final FirebaseFirestore firestore;
  final String uid;

  MyApp({super.key, required this.firestore, required this.uid});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> icons = iconTabBar.listIcons();

    return DefaultTabController(
      length: icons.length,
      child: MyNavBar(
        uid: uid,
        scrollController: 0.0,
      ),
    );
  }
}
