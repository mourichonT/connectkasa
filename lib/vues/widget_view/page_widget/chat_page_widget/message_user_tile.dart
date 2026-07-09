import 'package:connect_kasa/controllers/pages_controllers/chat_controller.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';

class MessageUserTile extends StatelessWidget {
  final double radius;
  final String idUserFrom;
  final String idUserTo;
  final String residenceId;
  final ChatController _chatController = ChatController();

  MessageUserTile({
    required this.residenceId,
    super.key,
    required this.radius,
    required this.idUserFrom,
    required this.idUserTo,
  });

  @override
  Widget build(BuildContext context) {
    final chatIdList = [idUserFrom, idUserTo]..sort();
    final chatIdStr = chatIdList.join("_");

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _chatController.chatInfoStream(
        residenceId: residenceId,
        chatId: chatIdStr,
      ),
      builder: (context, chatSnapshot) {
        final chatData = chatSnapshot.data;
        final lastMsg = chatData?["last_msg"] ?? "";
        final unread = (chatData != null)
            ? (idUserFrom == chatData["from_id"]
                ? chatData["from_msg_num"] ?? 0
                : chatData["to_msg_num"] ?? 0)
            : 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: ProfilTile(
                    idUserTo,
                    22,
                    19,
                    22,
                    true,
                    Colors.black87,
                    SizeFont.h2.size,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 65, top: 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
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
