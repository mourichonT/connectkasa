import 'package:flutter/material.dart';

class NoApprovalPage extends StatelessWidget {
  NoApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: SafeArea(
            child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Centrer verticalement
        children: [
          Center(
            // Centrer horizontalement
            child: Image.asset(
              "images/assets/logoCKvertconnectKasa.png",
              width: width / 1.5,
            ),
          ),
        ],
      ),
    )));
  }
}
