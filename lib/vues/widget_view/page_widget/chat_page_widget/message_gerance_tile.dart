// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/pages_controllers/chat_controller.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';

class MessageGeranceTile extends StatefulWidget {
  final double radius;
  final String idUserFrom;

  MessageGeranceTile({
    super.key,
    required this.radius,
    required this.idUserFrom,
  });

  @override
  State<StatefulWidget> createState() => MessageGeranceTileState();
}

class MessageGeranceTileState extends State<MessageGeranceTile> {
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  // final DataBasesUserServices _databasesUserServices = DataBasesUserServices();

  @override
  void initState() {
    super.initState();
    user = DataBasesUserServices.getUserById(widget.idUserFrom);
  }

  @override
  Widget build(BuildContext context) {
    //Color colorStatut = Theme.of(context).primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
              child: ProfilTile(widget.idUserFrom, 22, 19, 22, true,
                  Colors.black87, SizeFont.h2.size),
            ),
          ],
        ),
      ],
    );
  }
}
