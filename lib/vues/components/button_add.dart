import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

class ButtonAdd extends StatelessWidget {
  final Function? function;
  final Color color;
  final Color? colorText;
  final IconData? icon;
  final String? text;
  final double horizontal;
  final double vertical;
  final double size;
  final Color? borderColor;

  const ButtonAdd(
      {super.key,
      this.function,
      required this.color,
      this.icon,
      this.text,
      this.colorText,
      this.borderColor,
      required this.horizontal,
      required this.vertical,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (function != null) {
          function!(); // Appel de la fonction de participation si elle est définie
        }
      },
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border:Border.all(color: borderColor??Colors.transparent)
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: colorText ?? Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  MyTextStyle.lotName(
                      text ?? "", colorText ?? Colors.white, size)
                ],
              )
            : MyTextStyle.lotName(text!, colorText ?? Colors.white, size),
      ),
    );
  }
}
