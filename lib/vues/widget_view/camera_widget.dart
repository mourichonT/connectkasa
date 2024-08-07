import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class CameraWidget extends StatelessWidget {
  const CameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 40,
            color: Colors.black45,
          ),
          MyTextStyle.postDesc(
              "Prendre une photo", SizeFont.h3.size, Colors.black87)
        ],
      ),
    );
  }
}
