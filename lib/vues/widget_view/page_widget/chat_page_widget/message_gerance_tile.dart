// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/pages_controllers/chat_controller.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';

class MessageGeranceTile extends StatefulWidget {
  final double radius;
  final String idUserFrom;
  final String idUserTo;
  final String residenceId;

  MessageGeranceTile({
    super.key,
    required this.radius,
    required this.idUserFrom,
    required this.idUserTo,
    required this.residenceId,
  });

  @override
  State<StatefulWidget> createState() => MessageGeranceTileState();
}

class MessageGeranceTileState extends State<MessageGeranceTile> {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final ChatController chatController = ChatController();

  @override
  Widget build(BuildContext context) {
    final chatIdList = [widget.idUserFrom, widget.idUserTo]..sort();
    final chatIdStr = chatIdList.join("_");

    return StreamBuilder<Map<String, dynamic>?>(
      stream: chatController.chatInfoStream(
        residenceId: widget.residenceId,
        chatId: chatIdStr,
      ),
      builder: (context, chatSnapshot) {
        final chatData = chatSnapshot.data;
        final unread = (chatData != null)
            ? (widget.idUserTo == chatData["from_id"]
                ? chatData["from_msg_num"] ?? 0
                : chatData["to_msg_num"] ?? 0)
            : 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 5, bottom: 5, left: 5, right: 10),
                  child: ProfilTile(widget.idUserFrom, 22, 19, 22, true,
                      Colors.black87, SizeFont.h2.size),
                ),
              ],
            ),
            if (unread > 0)
              CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  "$unread",
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}
