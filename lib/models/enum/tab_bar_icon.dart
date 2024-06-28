import 'package:flutter/material.dart';

class IconTabBar {
  List<Map<String, dynamic>> listIcons() {
    return [
      {'icon': Icons.home_filled, 'size': 24.0},
      {'icon': Icons.campaign, 'size': 31.0},
      {'icon': Icons.event, 'size': 24.0},
      {'icon': Icons.handshake_outlined, 'size': 24.0},
      {'icon': Icons.folder_open, 'size': 24.0},
    ];
  }

  List<List<dynamic>> listIconsBottom() {
    return [
      [Icons.list_alt_outlined, "Contact"],
      [Icons.messenger_outline, "Message"],
    ];
  }
}
