import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

class ButtonAdd extends StatelessWidget {
  final Function? function;
  final Color color;
  final IconData? icon;
  final String text;
  final double horizontal;
  final double vertical;

  const ButtonAdd(
      {Key? key,
      this.function,
      required this.color,
      this.icon,
      required this.text,
      required this.horizontal,
      required this.vertical})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (function != null)
          function!(); // Appel de la fonction de participation si elle est définie
      },
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  MyTextStyle.lotName(text, Colors.white, 15)
                ],
              )
            : MyTextStyle.lotName(text, Colors.white, 15),
      ),
    );
  }
}