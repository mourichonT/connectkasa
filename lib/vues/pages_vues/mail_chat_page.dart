import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connect_kasa/controllers/services/databases_mail_services.dart';
import 'package:connect_kasa/models/pages_models/mail.dart';
import 'package:connect_kasa/vues/components/chat_bubble.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';

class MailChatPage extends StatefulWidget {
  final String agencyName;
  final Lot selectedLot;
  final List<Mail> mails;
  final List<String> to;
  final String uid;

  const MailChatPage({
    Key? key,
    required this.selectedLot,
    required this.agencyName,
    required this.mails,
    required this.uid,
    required this.to,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MailChatPageState();
}

class MailChatPageState extends State<MailChatPage> {
  final mailChatController = TextEditingController();
  final DatabasesMailServices _mailChatServices = DatabasesMailServices();
  final FocusNode _focusNode = FocusNode(); // Ajoutez le FocusNode

  void sendMail() async {
    if (mailChatController.text.isNotEmpty) {
      // Vérifier si  to n'est pas null
      await _mailChatServices.sendMail(
        selectedLot: widget.selectedLot,
        receiverId: widget.to,
        message: mailChatController.text,
        uid: widget.uid,
      );
      // Fermez le clavier
      setState(() {
        mailChatController.clear();
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
    super.dispose();
    mailChatController.dispose();
    _focusNode.dispose(); // Disposez le FocusNode
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(widget.agencyName, Colors.black),
        bottom: PreferredSize(
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
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildMessageList(),
              _buildInputMessage(),
              SizedBox(
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
        stream: _mailChatServices.getMail(
            widget.uid, widget.selectedLot, widget.to),
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error ${snapshot.error}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          return Expanded(
            child: ListView(
              children: snapshot.data!.docs
                  .map((document) => _buildMessageItem(document))
                  .toList(),
            ),
          );
        }));
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> mail = document.data() as Map<String, dynamic>;
    print(mail);
    var alignement =
        (mail["from"] != null) ? Alignment.centerLeft : Alignment.centerRight;

    var crossAlignement = (mail["to"] != null)
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end;

    return Container(
      alignment: alignement,
      child: Column(
        crossAxisAlignment: crossAlignement,
        children: [
          SizedBox(
            height: 10,
          ),
          ChatBubble(
            defColor: (mail["from"] != null)
                ? Colors.grey
                : Theme.of(context).primaryColor,
            message: mail["message"]["html"],
            onTap: () {
              if (isURL(mail["message"]["html"])) {
                // Vérifie si le message est une URL
                launchURL(Uri.parse(mail["message"]["html"]));
              }
            },
          ),
          MyTextStyle.chatdate(mail["delivery"]["startTime"]),
        ],
      ),
    );
  }

  Widget _buildInputMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            // Wrap TextFormField with Expanded
            child: TextFormField(
              focusNode: _focusNode, // Attachez le FocusNode
              controller: mailChatController,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                hintText: "Votre message",
                hintMaxLines: 15,
              ),
            ),
          ),
          IconButton(onPressed: sendMail, icon: Icon(Icons.send)),
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
}
