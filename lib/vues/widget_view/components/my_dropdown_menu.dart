// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class MyDropDownMenu extends StatefulWidget {
  final Lot? preferedLot;
  final double width;
  final String label;
  String hintText;
  bool inverseColor;
  final List<String> items;
  final Function(String) onValueChanged;

  MyDropDownMenu(this.width, this.label, this.hintText, this.inverseColor,
      {super.key,
      this.preferedLot,
      required this.items,
      required this.onValueChanged});

  @override
  MyDropDownMenuState createState() => MyDropDownMenuState();
}

class MyDropDownMenuState extends State<MyDropDownMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: widget.inverseColor
            ? Colors.white
            : Color(0xFFF5F6F9), // Light background color for the container
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: DropdownMenu<String>(
          inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none, // Supprime la bordure
            enabledBorder: InputBorder
                .none, // Supprime la bordure lorsque le champ est activé
            focusedBorder: InputBorder
                .none, // Supprime la bordure lorsque le champ est sélectionné
            errorBorder:
                InputBorder.none, // Supprime la bordure en cas d'erreur
            focusedErrorBorder: InputBorder
                .none, // Supprime la bordure en cas d'erreur et de focus
            disabledBorder: InputBorder
                .none, // Supprime la bordure lorsque le champ est désactivé
          ),
          hintText: widget.hintText,
          onSelected: (String? value) {
            if (value != null) {
              setState(() {
                widget.hintText = value;
                widget.onValueChanged(value);
              });
            }
          },
          dropdownMenuEntries:
              widget.items.map<DropdownMenuEntry<String>>((String value) {
            return DropdownMenuEntry<String>(
              value: value,
              label: value,
            );
          }).toList(),
          width: widget.width,
        ),
      ),
    );
  }
}
