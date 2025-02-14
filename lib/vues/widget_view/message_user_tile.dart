// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';

class MessageUserTile extends StatefulWidget {
  final String uid;
  final double radius;

  const MessageUserTile({
    required this.uid,
    super.key,
    required this.radius,
  });

  @override
  State<StatefulWidget> createState() => MessageUserTileState();
}

class MessageUserTileState extends State<MessageUserTile> {
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices _databasesUserServices = DataBasesUserServices();

  @override
  void initState() {
    super.initState();
    user = _databasesUserServices.getUserById(widget.uid);
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
              child: ProfilTile(widget.uid, 22, 19, 22, true, Colors.black87,
                  SizeFont.h2.size),
            ),
          ],
        ),
      ],
    );
  }
}
