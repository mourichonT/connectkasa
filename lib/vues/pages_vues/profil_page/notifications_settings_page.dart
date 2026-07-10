import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_user.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/notification_type.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatefulWidget {
  final User user;
  final Function refresh;

  const NotificationsSettingsPage(
      {super.key, required this.user, required this.refresh});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends State<NotificationsSettingsPage> {
  late Map<String, bool> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = Map<String, bool>.from(widget.user.notificationPrefs);
  }

  void _toggle(String key, String label, bool value) {
    setState(() {
      _prefs[key] = value;
      widget.user.notificationPrefs[key] = value;
    });
    SubmitUser.UpdateUser(
      context: context,
      uid: widget.user.uid,
      field: 'notificationPrefs.$key',
      label: label,
      newBool: value,
    );
    widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Notifications", Colors.black87, SizeFont.h1.size),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: NotificationType.all.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final key = NotificationType.all[index][0];
          final label = NotificationType.all[index][1];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyTextStyle.lotDesc(label, SizeFont.h3.size, FontStyle.normal),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _prefs[key] ?? true,
                    onChanged: (value) => _toggle(key, label, value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
