// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class MyDropDownMenu extends StatefulWidget {
  final Lot? preferedLot;
  final double width;
  final String? label;
  final String hintText;
  final bool inverseColor;
  final double? height;
  final List<String> items;
  final Function(String) onValueChanged;

  const MyDropDownMenu(this.width, this.label, this.hintText, this.inverseColor,
      {super.key,
      this.preferedLot,
      required this.items,
      required this.onValueChanged,
      this.height});

  @override
  State<MyDropDownMenu> createState() => MyDropDownMenuState();
}

class MyDropDownMenuState extends State<MyDropDownMenu> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.hintText; // Aucune sélection par défaut
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: widget.inverseColor ? Colors.white : const Color(0xFFF5F6F9),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
          child: DropdownMenu<String>(
            initialSelection: selectedValue,
            label: widget.label != null
                ? MyTextStyle.lotName(widget.label!, Colors.black54)
                : null,
            inputDecorationTheme: const InputDecorationTheme(
              border: InputBorder.none,
            ),
            hintText: widget.hintText,
            textStyle: TextStyle(
              color: Colors.black87,
              fontSize: SizeFont.h3.size,
              fontWeight: FontWeight.w400,
            ), // Affiché quand initialSelection est null
            onSelected: (String? value) {
              if (value != null) {
                setState(() {
                  selectedValue = value;
                });
                widget.onValueChanged(value);
              }
            },
            dropdownMenuEntries: widget.items.map((value) {
              return DropdownMenuEntry<String>(
                value: value,
                label: value,
              );
            }).toList(),
            width: widget.width,
          ),
        ),
      ),
    );
  }
}
