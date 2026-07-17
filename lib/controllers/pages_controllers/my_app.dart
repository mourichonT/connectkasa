import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/enum/tab_bar_icon.dart';
import '../../models/pages_models/lot.dart';
import 'my_nav_bar.dart';

class MyApp2 extends StatelessWidget {
  final IconTabBar iconTabBar = IconTabBar();
  final FirebaseFirestore firestore;
  final String uid;
  // Déjà résolus par LoginTransitionPage (getLotByIdUser + résolution du
  // lot préféré) avant la navigation : évite que MyNavBar._initializeLot
  // ne refasse la même requête Firestore juste après avoir atterri ici.
  final List<Lot>? initialLots;
  final Lot? initialPreferredLot;

  MyApp2({
    super.key,
    required this.firestore,
    required this.uid,
    this.initialLots,
    this.initialPreferredLot,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> icons = iconTabBar.listIcons();

    return DefaultTabController(
      length: icons.length,
      child: MyNavBar(
        uid: uid,
        scrollController: 0.0,
        initialLots: initialLots,
        initialPreferredLot: initialPreferredLot,
      ),
    );
  }
}
