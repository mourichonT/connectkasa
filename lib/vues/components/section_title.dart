import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;

  SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding( padding: EdgeInsets.symmetric(vertical: 30, horizontal:15),
      child: MyTextStyle.lotName(text),
      );
  }
}