import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';

class InGallery extends StatelessWidget {
  const InGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.attach_file,
            size: 40,
            color: Colors.black45,
          ),
          MyTextStyle.postDesc("Choisir un fichier", 13, Colors.black87)
        ],
      ),
    );
  }
}
