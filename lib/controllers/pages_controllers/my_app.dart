import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/enum/tab_bar_icon.dart';
import 'my_nav_bar.dart';

class MyApp2 extends StatelessWidget {
  final IconTabBar iconTabBar = IconTabBar();
  final FirebaseFirestore firestore;
  final String uid;

  MyApp2({super.key, required this.firestore, required this.uid});

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
