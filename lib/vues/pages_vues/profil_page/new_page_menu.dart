import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  final String uid;
  final Color color;
  final String? idLot;
  final bool isLogOut;
  final String text;
  final Icon icon;
  final VoidCallback? press;

  const ProfileMenu(
      {super.key,
      required this.text,
      required this.icon,
      this.press,
      required this.uid,
      required this.color,
      this.idLot,
      required this.isLogOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: EdgeInsets.all(isLogOut ? 12 : 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: (isLogOut) ? Colors.red[800]! : Color(0xFFF5F6F9),
        ),
        onPressed: press,
        child: Row(
          children: [
            icon,
            const SizedBox(width: 20),
            Expanded(
              child: Align(
                alignment: isLogOut ? Alignment.center : Alignment.centerLeft,
                child: MyTextStyle.postDesc(
                  text,
                  isLogOut ? SizeFont.h2.size : SizeFont.h3.size,
                  isLogOut ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (!isLogOut)
              Icon(
                Icons.arrow_forward_ios,
                color: isLogOut ? Colors.white : Color(0xFF757575),
              ),
          ],
        ),
      ),
    );
  }
}
