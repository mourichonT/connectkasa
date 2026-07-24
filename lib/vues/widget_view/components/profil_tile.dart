import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/agent_agency_name_provider.dart';
import 'package:konodal/core/providers/user_by_id_provider.dart';
import 'package:konodal/controllers/widgets_controllers/format_profil_pic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget profilTile(
    String uid, double radius1, double radius2, double size, bool pseudoHidden,
    [Color? color, double? pseudoFontSize]) {
  final FormatProfilPic formatProfilPic = FormatProfilPic();
  return Consumer(
    builder: (context, ref, child) {
      final userAsync = ref.watch(userByIdProvider(uid));
      final userUnique = userAsync.valueOrNull;
      if (userUnique != null) {
        // displayNameFor court-circuite le cas agent/agence (backoffice,
        // jamais de pseudo/surname renseigné - invite_agency_account
        // n'écrit que uid/email/accountType) avec l'affichage strict sur 2
        // lignes "{prenom}\n{nomAgence}"/"{nomAgence}" - le ConstrainedBox
        // + maxLines/overflow ci-dessous absorbe un nom de cabinet encore
        // trop long pour la largeur disponible (pas de Expanded/Flexible
        // ici : planterait dès que l'appelant place ce Row dans un
        // contexte de largeur non contrainte).
        final displayName = displayNameFor(ref, userUnique, (u) {
          // Extraire uniquement la première lettre de u.name et la mettre en majuscule
          String firstName = u.name;
          String formattedFirstName = firstName.isNotEmpty
              ? firstName[0].toUpperCase() // Première lettre en majuscule
              : ''; // Si le prénom est vide, on laisse une chaîne vide

          // Extraire seulement le premier mot de u.surname
          String surname = u.surname;
          String firstWordOfSurname = surname.isNotEmpty
              ? surname.split(' ')[0] // On prend le premier mot avant un espace
              : ''; // Si le nom est vide, on laisse une chaîne vide

          // Construire le nom à afficher : pseudo ou nom complet avec prénom formaté
          return (u.pseudo == null || u.pseudo == "")
              ? "$firstWordOfSurname $formattedFirstName" // Utilise le premier mot du nom et la première lettre du prénom
              : u.pseudo!;
        });

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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: MyTextStyle.lotName(
                        displayName,
                        color ?? Colors.black87,
                        pseudoFontSize,
                        null,
                        TextOverflow.ellipsis,
                        2),
                  ),
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: MyTextStyle.lotName(
                        displayName,
                        color ?? Colors.black87,
                        pseudoFontSize,
                        null,
                        TextOverflow.ellipsis,
                        2),
                  ),
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
