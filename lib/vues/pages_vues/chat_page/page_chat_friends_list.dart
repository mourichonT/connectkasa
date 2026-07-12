import 'dart:async';

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/subtitle_message.dart';
import 'package:flutter/material.dart';

class PageChatFriendsList extends StatefulWidget {
  final String uid;
  final String residence;
  final Lot selectedLot;

  const PageChatFriendsList({
    super.key,
    required this.uid,
    required this.residence,
    required this.selectedLot,
  });

  @override
  State<StatefulWidget> createState() => PageChatFriendsListState();
}

class PageChatFriendsListState extends State<PageChatFriendsList> {
  late Future<List<String>> listNumUsers;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 1,
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: MyTextStyle.lotName(
                  "Messages", Colors.black, SizeFont.h1.size),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1.0), // Hauteur du Divider
                child: Divider(
                  height: 0,
                  thickness: 0.2,
                  color: Colors.grey,
                ),
              ),
            ),
            body: TabBarView(children: [
              SubtitleMessage(
                residence: widget.residence,
                uid: widget.uid,
              ),
              SubtitleMessage(
                residence: widget.residence,
                uid: widget.uid,
                selectedLot: widget.selectedLot,
              ),
            ])));
  }
}
