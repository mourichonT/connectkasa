import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/pages_controllers/chat_controller.dart';
import 'package:konodal/controllers/providers/message_provider.dart';
import 'package:konodal/core/repositories/firestore_chat_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/profil_page/show_profil_page.dart';
import 'package:konodal/vues/widget_view/components/chat_bubble.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

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
  final FirestoreChatRepository _chatRepository = FirestoreChatRepository();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      chatController.text = widget.message!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider =
          Provider.of<MessageProvider>(context, listen: false);

      messageProvider.init(
        residenceId: widget.residence,
        userFrom: widget.idUserFrom,
        userTo: widget.idUserTo,
      );
      ChatController.clearMessage(
        userId: widget.idUserFrom,
        otherUserId: widget.idUserTo,
        residence: widget.residence,
      );
      // On considère que le message est vu
      messageProvider.clearNewMessageFlag();
    });
  }

  @override
  void dispose() {
    ChatController.clearMessage(
      userId: widget.idUserFrom,
      otherUserId: widget.idUserTo,
      residence: widget.residence,
    );
    chatController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (chatController.text.isNotEmpty) {
      final result = await _chatRepository.sendMessage(
        widget.idUserFrom,
        widget.idUserTo,
        capitalizeFirstLetter(chatController.text),
        widget.residence,
      );
      if (result.isSuccess) {
        chatController.clear();
        _focusNode.unfocus();
        _scrollToBottom();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi du message."),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetScroll = (maxScroll + 60).clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ShowProfilPage(
                      uid: widget.idUserTo,
                      currentUid: widget.idUserFrom,
                      refLot: widget.residence)),
            );

            // Refresh après retour de ChatPage
            //_fetchAllUsers();
          },
          child: profilTile(widget.idUserTo, 22, 19, 22, true, Colors.black87,
              SizeFont.h2.size),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 0,
            thickness: 0.2,
            color: Colors.grey,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputMessage(),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatRepository.getMessages(
          widget.idUserFrom, widget.idUserTo, widget.residence),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Error ${snapshot.error}");
        }
        if (!snapshot.hasData) {
          return const Center(child: AppLoader());
        }

        return snapshot.data!.when(
          success: (querySnapshot) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());

            return MessageList(
              messages: querySnapshot.docs,
              currentUserId: widget.idUserFrom,
              scrollController: _scrollController,
            );
          },
          failure: (error) => Text("Error $error"),
        );
      },
    );
  }

  Widget _buildInputMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              maxLines: 6,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              focusNode: _focusNode,
              controller: chatController,
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

  void launchURL(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
}

class MessageList extends StatelessWidget {
  final List<DocumentSnapshot> messages;
  final String currentUserId;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final data = messages[index].data() as Map<String, dynamic>;
        final isFromCurrentUser = data["userIdFrom"] == currentUserId;
        final alignement =
            isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
        final crossAlignement = isFromCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;

        return Container(
          alignment: alignement,
          child: Column(
            crossAxisAlignment: crossAlignement,
            children: [
              const SizedBox(height: 10),
              ChatBubble(
                defColor: isFromCurrentUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                message: data["message"],
                onTap: () {
                  if (RegExp(
                    r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
                  ).hasMatch(data["message"])) {
                    launchURL(Uri.parse(data["message"]));
                  }
                },
              ),
              MyTextStyle.chatdate(data["timestamp"]),
            ],
          ),
        );
      },
    );
  }

  void launchURL(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
