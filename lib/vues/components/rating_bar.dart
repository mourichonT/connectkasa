import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final int stars;
  final int percentage;

  const RatingBar({super.key, required this.stars, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nombre d'étoiles
        MyTextStyle.lotDesc('$stars', SizeFont.para.size),
        const SizedBox(width: 8),
        // Barre de progression
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            color: Colors.amber,
            minHeight: 7,
          ),
        ),
        
      ],
    );
  }
    
}
