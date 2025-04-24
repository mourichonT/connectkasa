import 'dart:ui';

class ColorUtils {
  static Color fromHex(String? hex,
      {Color fallback = const Color.fromRGBO(72, 119, 91, 1)}) {
    if (hex != null && hex.length >= 2) {
      try {
        return Color(int.parse(hex.substring(2), radix: 16) + 0xFF000000);
      } catch (_) {}
    }
    return fallback;
  }
}
