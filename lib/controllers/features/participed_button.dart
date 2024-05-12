import 'dart:math';

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:flutter/material.dart';

class PartipedTile extends StatefulWidget {
  // bool alreadyParticipated;
  final String residenceSelected;
  final Post post;
  final String uid;
  final double space;
  final int number;

  PartipedTile({
    //required this.alreadyParticipated,
    required this.residenceSelected,
    required this.post,
    required this.uid,
    required this.space,
    required this.number,
  });

  @override
  _PartipedTileState createState() => _PartipedTileState();
}

class _PartipedTileState extends State<PartipedTile> {
  bool alreadyParticipated = false;
  int userParticipatedCount = 0;
  late Future<List<User?>> participants;
  DataBasesUserServices dbService = DataBasesUserServices();
  //final GlobalKey _participantsListKey = GlobalKey(); // Ajout de la clé

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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.lotDesc(
              widget.post.setParticipant(userParticipatedCount),
              14,
              FontStyle.italic,
              FontWeight.w900,
            ),
            SizedBox(height: 10),
            buildParticipantsList(1, 5),
            SizedBox(height: 10),
          ],
        ),
        Row(
          children: [
            //Spacer(),
            alreadyParticipated
                ? ButtonAdd(
                    function: participedUser,
                    color: Colors.black38,
                    icon: Icons.cancel_outlined,
                    text: "Ne plus Participer",
                    horizontal: 10,
                    vertical: 2,
                  )
                : ButtonAdd(
                    function: participedUser,
                    color: Theme.of(context).primaryColor,
                    icon: Icons.check,
                    text: "Participer",
                    horizontal: 10,
                    vertical: 2,
                  ),
          ],
        ),
      ],
    );
  }

  Widget buildParticipantsList(double space, int number) {
    return FutureBuilder<List<User?>>(
      //key: _participantsListKey,
      future: participants,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Afficher un indicateur de chargement en attendant les données
        } else {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<User?>? users = snapshot.data;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0;
                    i < min(userParticipatedCount, widget.number);
                    i++)
                  Container(
                      padding: EdgeInsets.all(widget.space),
                      child: buildAvatar(users![i])),
              ],
            );
          }
        }
      },
    );
  }

  Widget buildAvatar(User? user) {
    if (user != null && user.profilPic != null && user.profilPic != "") {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(user.profilPic!),
      );
    } else {
      String? initName = user?.name;
      String? initSurname = user?.surname;

      List<String> lettresNom = [];
      List<String> lettresPrenom = [];
      if (initName != null) {
        for (int i = 0; i < initName.length; i++) {
          lettresNom.add(initName[i]);
        }
      }
      if (initName != null) {
        for (int i = 0; i < initSurname!.length; i++) {
          lettresPrenom.add(initSurname[i]);
        }
      }

      String initiale = "";
      if (lettresNom.isNotEmpty && lettresPrenom.isNotEmpty) {
        initiale = "${lettresNom.first}${lettresPrenom.first}";
      } else {
        // Handle the case where one of the lists is empty
        // For example, set a default value for initiale
      }

      return Container(
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor, width: 1),
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(initiale), // Utilisez votre style ici
        ),
      );
    }
  }

  void participedUser() async {
    if (!alreadyParticipated) {
      await DataBasesPostServices().updatePostParticipants(
        widget.residenceSelected,
        widget.post.id,
        widget.uid,
      );
      setState(() {
        alreadyParticipated = true;
        userParticipatedCount++;
        participants = getUsersForParticipants(widget.post.participants!);
        //buildParticipantsList(widget.space, widget.number);
      });
    } else {
      await DataBasesPostServices().removePostParticipants(
        widget.residenceSelected,
        widget.post.id,
        widget.uid,
      );

      setState(() {
        alreadyParticipated = false;
        userParticipatedCount--;
        participants = getUsersForParticipants(widget.post.participants!);
        // buildParticipantsList(widget.space, widget.number);
      });
    }
  }

  Future<List<User?>> getUsersForParticipants(
      List<String> participantIds) async {
    List<User?> users = [];
    for (String id in participantIds) {
      User? user = await dbService.getUserById(id);
      users.add(user);
    }
    return users;
  }
}
