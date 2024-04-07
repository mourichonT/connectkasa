// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;

  SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
      child: MyTextStyle.lotName(text, Colors.black87),
    );
  }
}
