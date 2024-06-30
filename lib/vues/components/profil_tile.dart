import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';

Widget ProfilTile(
    String uid, double radius1, double radius2, double size, bool pseudoHidden,
    [Color? color, double? pseudoFontSize]) {
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  return FutureBuilder<User?>(
    future: user = databasesUserServices.getUserById(uid),
    builder: (context, snapshot) {
      // Maintenant, vous pouvez utiliser l'objet User ici
      if (snapshot.hasData && snapshot.data != null) {
        var userUnique = snapshot.data!;
        if (userUnique.profilPic != null && userUnique.profilPic != "") {
          // Retourner le widget avec l'image de profil si disponible
          return Row(
            children: [
              CircleAvatar(
                radius: radius1,
                backgroundColor: Theme.of(context).primaryColor,
                child: formatProfilPic.ProfilePic(radius2, userUnique, size),
              ),
              if (pseudoHidden)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: MyTextStyle.lotName(userUnique.pseudo!,
                      color ?? Colors.black87, pseudoFontSize),
                )
            ],
          );
        } else {
          // Sinon, retourner les initiales
          return Row(
            children: [
              CircleAvatar(
                radius: radius1,
                backgroundColor: Theme.of(context).primaryColor,
                child: formatProfilPic.getInitiales(radius2, userUnique, size),
              ),
              if (pseudoHidden)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: MyTextStyle.lotName(userUnique.pseudo!,
                      color ?? Colors.black87, pseudoFontSize),
                )
            ],
          );
        }
      } else {
        // Gérer le cas où le futur est résolu mais qu'il n'y a pas de données
        return Row(
          children: [
            CircleAvatar(
              radius: radius1,
              backgroundColor: Theme.of(context).primaryColor,
              child: formatProfilPic.ProfilePic(radius2, null, size),
            ),
            SizedBox(
              width: 5,
            ),
            if (pseudoHidden)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: MyTextStyle.lotName("Utilisteur inconnu",
                    color ?? Colors.black87, pseudoFontSize),
              ),
          ],
        ); // ou tout autre widget par défaut
      }
    },
  );
}
