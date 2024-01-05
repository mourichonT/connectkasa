import 'package:connect_kasa/controllers/pages_controllers/my_app.dart';
import 'package:connect_kasa/models/datas/datas_lots.dart';
import 'package:flutter/material.dart';

void main() {

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      useMaterial3: true,
    ),
    home: MyApp(),
  ));
}
