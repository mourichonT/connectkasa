import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/vues/pages_vues/login_page_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ColorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: colorProvider.color,
              secondary: colorProvider.color,
              surface: colorProvider.color.withOpacity(0.1),
              error: Colors.red,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.black,
              onError: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: LoginPageView(
            firestore: FirebaseFirestore.instance,
          ),
        );
      },
    );
  }
}
