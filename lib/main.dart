import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/vues/pages_vues/login_page_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  tzdata.initializeTimeZones();
  tz.setLocalLocation(
      tz.getLocation('Europe/Paris')); // Définir le fuseau horaire local

  final db = FirebaseFirestore.instance;

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: const Color.fromRGBO(72, 119, 91, 1)),
      useMaterial3: true,
    ),
    home: LoginPageView(
      firestore: db,
    ),
    //     MyApp(
    //   firestore: db,
    // ),
  ));
}
