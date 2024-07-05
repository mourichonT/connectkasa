// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class LogoWidget extends StatefulWidget {
  const LogoWidget({super.key});

  @override
  _LogoWidgetState createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<LogoWidget> {
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    precacheImage(const AssetImage("images/logoCK.png"), context)
        .then((value) => setState(() {
              _imageLoaded = true;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return _imageLoaded
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor, BlendMode.overlay),
            child: Image.asset(
              "images/logoCK.png",
              width: 150,
              fit: BoxFit.contain,
            ),
          )
        : Container(); // Placeholder widget or empty container
  }
}
