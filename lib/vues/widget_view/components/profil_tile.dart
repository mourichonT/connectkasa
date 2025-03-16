import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';

Widget ProfilTile(
    String uid, double radius1, double radius2, double size, bool pseudoHidden,
    [Color? color, double? pseudoFontSize]) {
  final double radiusT = radius2;
  late Future<User?> user;
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  final DataBasesUserServices databasesUserServices = DataBasesUserServices();
  return FutureBuilder<User?>(
    future: user = databasesUserServices.getUserById(uid),
    builder: (context, snapshot) {
      // Maintenant, vous pouvez utiliser l'objet User ici
      if (snapshot.hasData && snapshot.data != null) {
        var userUnique = snapshot.data!;

        // Extraire uniquement la première lettre de userUnique.name et la mettre en majuscule
        String firstName = userUnique.name;
        String formattedFirstName = firstName.isNotEmpty
            ? firstName[0].toUpperCase() // Première lettre en majuscule
            : ''; // Si le prénom est vide, on laisse une chaîne vide

        // Extraire seulement le premier mot de userUnique.surname
        String surname = userUnique.surname;
        String firstWordOfSurname = surname.isNotEmpty
            ? surname.split(' ')[0] // On prend le premier mot avant un espace
            : ''; // Si le nom est vide, on laisse une chaîne vide

        // Construire le nom à afficher : pseudo ou nom complet avec prénom formaté
        String displayName = (userUnique.pseudo == null ||
                userUnique.pseudo == "")
            ? "$firstWordOfSurname $formattedFirstName" // Utilise le premier mot du nom et la première lettre du prénom
            : userUnique.pseudo!;

        if (userUnique.profilPic != null && userUnique.profilPic != "") {
          // Retourner le widget avec l'image de profil si disponible
          return Row(
            children: [
              CircleAvatar(
                radius: radius1,
                backgroundColor: Theme.of(context).primaryColor,
                child: formatProfilPic.ProfilePic(radius1, userUnique, size),
              ),
              if (pseudoHidden)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: MyTextStyle.lotName(
                      displayName, color ?? Colors.black87, pseudoFontSize),
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
                  child: MyTextStyle.lotName(
                      displayName, color ?? Colors.black87, pseudoFontSize),
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
            const SizedBox(
              width: 5,
            ),
            if (pseudoHidden)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: MyTextStyle.lotName("Utilisateur inconnu",
                    color ?? Colors.black87, pseudoFontSize),
              ),
          ],
        ); // ou tout autre widget par défaut
      }
    },
  );
}
