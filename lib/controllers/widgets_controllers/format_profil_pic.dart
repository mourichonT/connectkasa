// ignore_for_file: non_constant_identifier_names

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FormatProfilPic {
  Widget getInitiales(double raduis, User user, double size) {
    String initName = user.name.trim();
    String initSurname = user.surname.trim();

    String firstLetterNom =
        initName.isNotEmpty ? initName[0].toUpperCase() : '';
    String firstLetterPrenom =
        initSurname.isNotEmpty ? initSurname[0].toUpperCase() : '';

    String initiale = (firstLetterNom + firstLetterPrenom).isNotEmpty
        ? "$firstLetterNom$firstLetterPrenom"
        : "??";

    return CircleAvatar(
      radius: raduis,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: MyTextStyle.initialAvatar(initiale, size),
        ),
      ),
    );
  }

  // Widget getInitiales(double raduis, User user, double size) {
  //   // Une fois que le futur est résolu, vous pouvez accéder aux propriétés de l'utilisateur

  //   String? initName = user.name;
  //   String? initSurname = user.surname;

  //   List<String> lettresNom = [];
  //   List<String> lettresPrenom = [];

  //   for (int i = 0; i < initName.length; i++) {
  //     lettresNom.add(initName[i]);
  //   }
  //   for (int i = 0; i < initSurname.length; i++) {
  //     lettresPrenom.add(initSurname[i]);
  //   }

  //   String initiale = "${lettresNom.first}${lettresPrenom.first}";

  //   return CircleAvatar(
  //     radius: raduis,
  //     child: Container(
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         shape: BoxShape.circle,
  //       ),
  //       child: Center(
  //         child: MyTextStyle.initialAvatar(initiale, size),
  //       ),
  //     ),
  //   );
  // }

  Widget ProfilePic(double radius, User? userPost, double size) {
    if (userPost != null &&
        userPost.profilPic != null &&
        userPost.profilPic != "") {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(
          userPost.profilPic!,
        ),
      );
    } else {
      // Retourner un widget par défaut si les conditions ne sont pas remplies
      return CircleAvatar(
        radius: radius,
        // Par exemple, vous pouvez utiliser une image par défaut ou des initiales
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: MyTextStyle.initialAvatar("!?", size),
          ),
        ), // Par défaut, afficher simplement "A"
      );
    }
  }
}
