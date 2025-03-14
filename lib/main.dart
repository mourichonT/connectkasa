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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            tabBarTheme:
                const TabBarTheme(dividerColor: Colors.black38, dividerHeight: 0.5),
            dividerTheme: const DividerThemeData(
              color: Colors.black38, // Couleur principale du diviseur
              thickness: 0.5, // Épaisseur du diviseur
              space: 20, // Espace entre les diviseurs
            ),
            colorScheme: ColorScheme.light(
              outline: Colors.black26,
              primary: colorProvider.color,
              secondary: colorProvider.color,
              surface: Colors.white,
              error: Colors.red,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: const Color.fromARGB(221, 52, 52, 52),
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
