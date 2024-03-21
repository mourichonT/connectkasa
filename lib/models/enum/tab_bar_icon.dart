import 'package:flutter/material.dart';

class IconTabBar {
  List<IconData> listIcons() {
    return [
      Icons.home_filled,
      Icons.notifications_active_outlined,
      Icons.event,
      Icons.webhook,
      //Icons.hub_sharp,
      Icons.folder_open,
      //Icons.account_circle_outlined
    ];
  }

  List<List<dynamic>> listIconsBottom() {
    return [
      [Icons.list_alt_outlined, "Contact"],
      [Icons.messenger_outline, "Message"],
    ];
  }
}
