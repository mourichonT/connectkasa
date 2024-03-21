// ignore_for_file: non_constant_identifier_names

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FormatProfilPic {
  final DataBasesUserServices databaseServices = DataBasesUserServices();
  late Future<User?> userPost;

  Widget getInitiales(
      double raduis, Future<User?> userPostFuture, double size) {
    return FutureBuilder<User?>(
      future: userPostFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Retourner un indicateur de chargement pendant que le futur est en cours de résolution
          return const Center(child: CircularProgressIndicator());
        } else {
          // Une fois que le futur est résolu, vous pouvez accéder aux propriétés de l'utilisateur
          var userPost = snapshot.data;
          if (userPost != null) {
            String? initName = userPost.name;
            String? initSurname = userPost.surname;

            List<String> lettresNom = [];
            List<String> lettresPrenom = [];

            for (int i = 0; i < initName.length; i++) {
              lettresNom.add(initName[i]);
            }
            for (int i = 0; i < initSurname.length; i++) {
              lettresPrenom.add(initSurname[i]);
            }

            String initiale = "${lettresNom.first}${lettresPrenom.first}";

            return Container(
              height: raduis,
              width: raduis,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: MyTextStyle.initialAvatar(initiale, size),
              ),
            );
          } else {
            // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
            return const SizedBox(); // ou tout autre widget par défaut
          }
        }
      },
    );
  }

  FutureBuilder<User?> ProfilePic(double radius, Future<User?> userPost) {
    return FutureBuilder<User?>(
      future: userPost,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Retourner un indicateur de chargement pendant que le futur est en cours de résolution
          return const Center(child: CircularProgressIndicator());
        } else {
          // Une fois que le futur est résolu, vous pouvez accéder aux propriétés de l'utilisateur
          var userPost = snapshot.data;
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
              child: const Text("CK"), // Par défaut, afficher simplement "A"
            );
          }
        }
      },
    );
  }
}
