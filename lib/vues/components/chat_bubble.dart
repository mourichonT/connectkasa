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
        constraints: BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: defColor.withOpacity(0.5),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          softWrap: true,
        ),
      ),
    );
  }
}
