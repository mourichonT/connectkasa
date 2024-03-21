import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:flutter/material.dart';

class DetailContactView extends StatelessWidget {
  final Contact contact;

  const DetailContactView({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
      title: MyTextStyle.lotName(contact.name, Colors.black87),
    ));
  }
}
