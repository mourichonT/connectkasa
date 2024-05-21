import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/bottom_sheet/multi_select_bottom_sheet_field.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

Widget MyMultiSelectedDropDown(
    {required GlobalKey<FormFieldState<dynamic>>? myKey,
    required double width,
    required String label,
    required Color color,
    required List<MultiSelectItem<String?>> items,
    required Function(List<String?>) onConfirm,
    required Function(String?)? onTap}) {
  return Expanded(
    child: Container(
      width: width,
      child: MultiSelectBottomSheetField<String?>(
        key: myKey,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        title: MyTextStyle.annonceDesc("Recherche", 16, 1),
        buttonText: MyTextStyle.lotDesc(
          label,
          13,
          FontStyle.normal,
        ),
        checkColor: Colors.white,
        selectedColor: color,
        items: items,
        searchable: true,
        buttonIcon: Icon(
          Icons.arrow_drop_down,
          size: 24,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black12, // Changez la couleur ici
              width: 1, // Ajustez l'épaisseur de la ligne si nécessaire
            ),
          ),
        ),
        onConfirm: onConfirm,
        chipDisplay: MultiSelectChipDisplay(
          height: 50,
          onTap: onTap,
        ),
      ),
    ),
  );
}
