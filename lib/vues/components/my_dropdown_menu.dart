// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class MyDropDownMenu extends StatefulWidget {
  final Lot preferedLot;
  final double width;
  final String label;
  String hintText;
  final List<String> items;
  final Function(String) onValueChanged;

  MyDropDownMenu(this.width, this.label, this.hintText,
      {super.key,
      required this.preferedLot,
      required this.items,
      required this.onValueChanged});

  @override
  MyDropDownMenuState createState() => MyDropDownMenuState();
}

class MyDropDownMenuState extends State<MyDropDownMenu> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      //padding: EdgeInsets.symmetric(horizontal: 10),
      width: widget.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyTextStyle.lotName(
              "${widget.label} :", Colors.black87, SizeFont.h3.size),
          DropdownMenu<String>(
            //initialSelection: typeDeclaration,
            hintText: widget.hintText,
            onSelected: (String? value) {
              // This is called when the user selects an item.
              setState(() {
                widget.hintText = value!;
                widget.onValueChanged(value);
              });
            },
            dropdownMenuEntries:
                widget.items.map<DropdownMenuEntry<String>>((String value) {
              return DropdownMenuEntry<String>(
                value: value,
                label: value,
              );
            }).toList(),
            width: widget.width / 1.8,
          )
        ],
      ),
    );
  }
}
