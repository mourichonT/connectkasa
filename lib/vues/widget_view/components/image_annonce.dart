
import 'package:flutter/material.dart';

Widget ImageAnnounced(BuildContext context, double width, double height) {
  return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(color: Colors.black12),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.black26,
          size: width / 3,
        ),
      ));
}
