import 'dart:math';

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';

class PartipedTile extends StatefulWidget {
  final String residenceSelected;
  final Post post;
  final String uid;
  final double space;
  final int number;
  final double sizeFont;

  const PartipedTile({
    super.key,
    required this.residenceSelected,
    required this.post,
    required this.uid,
    required this.space,
    required this.number,
    required this.sizeFont,
  });

  @override
  _PartipedTileState createState() => _PartipedTileState();
}

class _PartipedTileState extends State<PartipedTile> {
  bool alreadyParticipated = false;
  int userParticipatedCount = 0;
  late Future<List<User?>> participants;
  DataBasesUserServices dbService = DataBasesUserServices();

  @override
  void initState() {
    super.initState();
    alreadyParticipated = widget.post.participants!.contains(widget.uid);
    userParticipatedCount = widget.post.participants!.length;
    participants = getUsersForParticipants(widget.post.participants!);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.lotDesc(
              widget.post.setParticipant(userParticipatedCount),
              widget.sizeFont,
              FontStyle.italic,
              FontWeight.w900,
            ),
            const SizedBox(height: 15),
            participants != null ? buildParticipantsList(0, 5) : Container(),
            const SizedBox(height: 15),
          ],
        ),
        alreadyParticipated
            ? ButtonAdd(
                function: participedUser,
                color: Colors.black38,
                icon: Icons.cancel_outlined,
                text: "Se désengager",
                horizontal: 10,
                vertical: 2,
                size: SizeFont.h3.size,
              )
            : ButtonAdd(
                function: participedUser,
                color: Theme.of(context).primaryColor,
                icon: Icons.check,
                text: "Participer",
                horizontal: 10,
                vertical: 2,
                size: SizeFont.h3.size,
              ),
      ],
    );
  }

  Widget buildParticipantsList(double space, int number) {
    return FutureBuilder<List<User?>>(
      future: participants,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Afficher un indicateur de chargement en attendant les données
        } else {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<User?>? users = snapshot.data;

            if (users == null || users.isEmpty) {
              return MyTextStyle.annonceDesc(
                  'Aucun participant', SizeFont.h3.size, 1);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0;
                    i < min(userParticipatedCount, widget.number);
                    i++)
                  if (i < users.length && users[i] != null)
                    Container(
                      padding: EdgeInsets.all(widget.space),
                      child: ProfilTile(users[i]!.uid, 12, 11, 12, false),
                    ),
              ],
            );
          }
        }
      },
    );
  }

  Future<void> participedUser() async {
    if (!alreadyParticipated) {
      await DataBasesPostServices().updatePostParticipants(
        widget.residenceSelected,
        widget.post.id,
        widget.uid,
      );
      setState(() {
        alreadyParticipated = true;
        widget.post.participants!
            .add(widget.uid); // Mise à jour de la liste des participants
        userParticipatedCount++;
        participants = getUsersForParticipants(widget.post.participants!);
      });
    } else {
      await DataBasesPostServices().removePostParticipants(
        widget.residenceSelected,
        widget.post.id,
        widget.uid,
      );
      setState(() {
        alreadyParticipated = false;
        widget.post.participants!
            .remove(widget.uid); // Mise à jour de la liste des participants
        userParticipatedCount--;
        participants = getUsersForParticipants(widget.post.participants!);
      });
    }
  }

  Future<List<User?>> getUsersForParticipants(
      List<String> participantIds) async {
    List<User?> users = [];
    for (String id in participantIds) {
      User? user = await DataBasesUserServices.getUserById(id);
      users.add(user);
    }
    return users;
  }
}
