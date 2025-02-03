import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/chat_services.dart';
import 'package:connect_kasa/vues/components/chat_bubble.dart';
import 'package:connect_kasa/vues/widget_view/message_user_tile.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String residence;
  final String idUserFrom;
  final String idUserTo;
  final String? message;

  const ChatPage({
    super.key,
    required this.idUserFrom,
    required this.idUserTo,
    required this.residence,
    this.message,
  });

  @override
  State<StatefulWidget> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final chatController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final FocusNode _focusNode = FocusNode();

  void sendMessage() async {
    if (chatController.text.isNotEmpty) {
      await _chatServices.sendMessage(widget.idUserFrom, widget.idUserTo,
          chatController.text, widget.residence);

      setState(() {
        chatController.clear();
        _focusNode.unfocus();
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    chatController.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MessageUserTile(radius: 16, uid: widget.idUserTo),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0), // Hauteur du Divider
          child: Divider(
            height: 0,
            thickness: 0.2,
            color: Colors.grey,
          ),
        ),
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: _buildMessageList(),
              ),
              _buildInputMessage(),
              const SizedBox(
                height: 25,
              ),
              //TextField
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
        stream: _chatServices.getMessages(
            widget.idUserFrom, widget.idUserTo, widget.residence),
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error ${snapshot.error}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return ListView(
            children: snapshot.data!.docs
                .map((document) => _buildMessageItem(document))
                .toList(),
          );
        }));
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    var alignement = (data["userIdFrom"] == widget.idUserFrom)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    var crossAlignement = (data["userIdFrom"] == widget.idUserFrom)
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Container(
      alignment: alignement,
      child: Column(
        crossAxisAlignment: crossAlignement,
        children: [
          const SizedBox(
            height: 10,
          ),
          ChatBubble(
            defColor: (data["userIdFrom"] == widget.idUserFrom)
                ? Colors.grey
                : Theme.of(context).primaryColor,
            message: data["message"],
            onTap: () {
              if (isURL(data["message"])) {
                // Vérifie si le message est une URL
                launchURL(Uri.parse(data["message"]));
              }
            },
          ),
          MyTextStyle.chatdate(data["timestamp"]),
        ],
      ),
    );
  }

  void launchURL(Uri uri) async {
    if (await canLaunchUrl(Uri.parse(uri.toString()))) {
      await launchUrl(Uri.parse(uri.toString()));
    } else {
      throw 'Could not launch $uri';
    }
  }

  bool isURL(String text) {
    final RegExp urlRegex = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
    );
    return urlRegex.hasMatch(text);
  }

  Widget _buildInputMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            // Wrap TextFormField with Expanded
            child: TextFormField(
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              focusNode: _focusNode,
              controller: widget.message != null
                  ? TextEditingController(text: widget.message)
                  : chatController,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                hintText: "Votre message",
                hintMaxLines: 15,
              ),
            ),
          ),
          IconButton(onPressed: sendMessage, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}
