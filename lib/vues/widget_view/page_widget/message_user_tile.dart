import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/pages_controllers/chat_controller.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';

class MessageUserTile extends StatefulWidget {
  final double radius;
  final String idUserFrom;
  final String idUserTo;
  final String residenceId;

  MessageUserTile({
    required this.residenceId,
    super.key,
    required this.radius,
    required this.idUserFrom,
    required this.idUserTo,
  });

  @override
  State<StatefulWidget> createState() => MessageUserTileState();
}

class MessageUserTileState extends State<MessageUserTile> {
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final ChatController chatController = ChatController();

  @override
  void initState() {
    super.initState();
    // On charge juste l'user une fois, pas de setState ici
    user = DataBasesUserServices.getUserById(widget.idUserFrom);
  }

  @override
  Widget build(BuildContext context) {
    final chatIdList = [widget.idUserFrom, widget.idUserTo]..sort();
    final chatIdStr = chatIdList.join("_");

    return FutureBuilder<User?>(
      future: user,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final userData = snapshot.data!;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: chatController.chatInfoStream(
            residenceId: widget.residenceId,
            chatId: chatIdStr,
          ),
          builder: (context, chatSnapshot) {
            final chatData = chatSnapshot.data;
            final lastMsg = chatData?["last_msg"] ?? "";
            final unread = (chatData != null)
                ? (widget.idUserFrom == chatData["from_id"]
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
                        widget.idUserTo,
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
      },
    );
  }
}
