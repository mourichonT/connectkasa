// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';

class MessageUserTile extends StatefulWidget {
  final String uid;
  final double radius;

  MessageUserTile({
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
                  const EdgeInsets.only(top: 10, bottom: 5, left: 5, right: 15),
              child: CircleAvatar(
                radius: widget.radius,
                backgroundColor: Theme.of(context).primaryColor,
                child: FutureBuilder<User?>(
                  future: user,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else {
                      if (snapshot.hasData && snapshot.data != null) {
                        var user = snapshot.data!;
                        if (user.profilPic != null && user.profilPic != "") {
                          return formatProfilPic.ProfilePic(
                              27, Future.value(user));
                        } else {
                          return formatProfilPic.getInitiales(
                              40, Future.value(user), 18);
                        }
                      } else {
                        return formatProfilPic.getInitiales(
                            37, Future.value(user), 25);
                      }
                    }
                  },
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FutureBuilder<User?>(
                      future: user,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        } else if (snapshot.hasData && snapshot.data != null) {
                          var user = snapshot.data!;
                          String? pseudo = user.pseudo;
                          return MyTextStyle.lotName(pseudo!, Colors.black87);
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
