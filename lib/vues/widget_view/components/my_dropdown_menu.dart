// ignore_for_file: must_be_immutable

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
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
  // Valeur déjà sélectionnée à afficher au premier rendu (ex: catégorie
  // existante d'une annonce en modification) - hintText reste le texte de
  // repli quand rien n'est présélectionné, comme avant cet ajout.
  final String? initialValue;

  const MyDropDownMenu(this.width, this.label, this.hintText, this.inverseColor,
      {super.key,
      this.preferedLot,
      required this.items,
      required this.onValueChanged,
      this.height,
      this.initialValue});

  @override
  State<MyDropDownMenu> createState() => MyDropDownMenuState();
}

class MyDropDownMenuState extends State<MyDropDownMenu> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue ?? widget.hintText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: widget.inverseColor ? Colors.white : const Color(0xFFF5F6F9),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
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
            // Sans hauteur maximale, le menu se dimensionne pour afficher
            // tous les items (jusqu'à 21 pour les secteurs d'activité) et
            // Flutter le repositionne alors au-dessus du champ dès qu'il n'y
            // a pas assez de place en dessous - donnant l'impression qu'il
            // recouvre toute la page. Une hauteur fixe force un menu
            // scrollable qui reste ancré sous le champ.
            menuHeight: 300,
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
