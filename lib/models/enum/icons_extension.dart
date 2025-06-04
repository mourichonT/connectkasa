import 'package:flutter/material.dart';

// Define the enum with extensions
enum IconsExtension {
  doc,
  pdf,
  jpg,
  png,
  xls,
  zip,
  mp3,
}

// Extension method on the enum to return the corresponding Image asset
extension IconsExtensionAssets on IconsExtension {
  Image get icon {
    switch (this) {
      case IconsExtension.doc:
        return Image.asset('images/icon_extension/doc.png');
      case IconsExtension.pdf:
        return Image.asset('images/icon_extension/pdf.png');
      case IconsExtension.jpg:
        return Image.asset('images/icon_extension/jpg.png');
      case IconsExtension.png:
        return Image.asset('images/icon_extension/png.png');
      case IconsExtension.xls:
        return Image.asset('images/icon_extension/xls.png');
      case IconsExtension.zip:
        return Image.asset('images/icon_extension/zip.png');
      case IconsExtension.mp3:
        return Image.asset('images/icon_extension/mp3.png');
      default:
        return Image.asset(
            'images/icon_extension/default.png'); // Fixed default case
    }
  }
}

IconsExtension? getFileType(String? extension) {
  switch (extension) {
    case 'doc':
      return IconsExtension.doc;
    case 'pdf':
      return IconsExtension.pdf;
    case 'jpg':
      return IconsExtension.jpg;
    case 'png':
      return IconsExtension.png;
    case 'xls':
      return IconsExtension.xls;
    case 'zip':
      return IconsExtension.zip;
    case 'mp3':
      return IconsExtension.mp3;
    default:
      return null; // Handle unknown extensions
  }
}
