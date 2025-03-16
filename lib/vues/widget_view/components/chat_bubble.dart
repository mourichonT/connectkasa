import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final Color defColor;
  final VoidCallback onTap;

  const ChatBubble(
      {super.key,
      required this.message,
      required this.defColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: defColor.withOpacity(0.5),
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: SizeFont.h3.size, color: Colors.black87),
          softWrap: true,
        ),
      ),
    );
  }
}
