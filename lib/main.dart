import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/pages_controllers/my_nav_bar.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/providers/lot_provider.dart';
import 'package:connect_kasa/controllers/providers/name_lot_provider.dart';
import 'package:connect_kasa/vues/pages_vues/login_page_view.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "dotenv.env");

  await initializeDateFormatting('fr');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  tzdata.initializeTimeZones();
  tz.setLocalLocation(
      tz.getLocation('Europe/Paris')); // Définir le fuseau horaire local

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ColorProvider()),
      ChangeNotifierProvider(create: (context) => NameLotProvider()),
      ChangeNotifierProvider(create: (_) => LotProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        // Détermine la luminosité de la couleur principale
        final brightness = ThemeData.estimateBrightnessForColor(
            Color.lerp(colorProvider.color, Colors.white, 0.90) ??
                Colors.white);
        final isDark = brightness == Brightness.dark;

        // Définit le style des icônes système (Android + iOS)
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark, // Android
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light, // iOS
        ));

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            tabBarTheme: const TabBarTheme(
                dividerColor: Colors.black38, dividerHeight: 0.5),
            dividerTheme: const DividerThemeData(
              color: Colors.black38,
              thickness: 0.5,
              space: 20,
            ),
            colorScheme: ColorScheme.light(
              outline: Colors.black26,
              primary: colorProvider.color,
              secondary: Color.lerp(colorProvider.color, Colors.white, 0.90) ??
                  Colors.white,
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
          onGenerateRoute: (settings) {
            if (settings.name == '/MyNavBar') {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MyNavBar(uid: settings.arguments as String),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              );
            }
            return null;
          },
        );
      },
    );
  }
}
