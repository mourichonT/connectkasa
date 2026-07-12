import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/widget_view/components/my_text_fied.dart';
import 'package:flutter/material.dart';

class LookUpUser {
  static Future<String?> searchUserForm(
      BuildContext context, DemandeLoc demande) {
    final TextEditingController emailController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Destinataire", Colors.black87, SizeFont.h2.size),
          content: MyTextField(
              hintText: "Mail ou N° utilisateur",
              osbcureText: false,
              padding: 0,
              autofocus: false,
              controller: emailController),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // L'utilisateur annule
              },
              child: MyTextStyle.lotName(
                  "Annuler", Colors.black54, SizeFont.h3.size,
                  FontWeight.normal),
            ),
            TextButton(
              onPressed: () async {
                String input = emailController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Veuillez entrer une adresse email ou un N° utilisateur')),
                  );
                  return; // Ne pas fermer le dialog
                }

                // Recherche utilisateur
                User? user = await FirestoreUserRepository()
                    .getUserWithEmailOrRefApp(input, input)
                    .then((result) => result.when(
                        success: (v) => v, failure: (_) => null));

                if (user != null) {
                  // L'utilisateur existe -> partage du fichier
                  final result = await FirestoreUserRepository()
                      .shareFile(demande, user.uid);
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {
                      Navigator.of(context).pop(input); // Fermer avec succès
                    },
                    failure: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'envoi : $error'),
                        ),
                      );
                    },
                  );
                } else {
                  // Aucun utilisateur trouvé
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: MyTextStyle.lotName(
                          "Erreur", Colors.red[800]!, SizeFont.h2.size),
                      content: MyTextStyle.annonceDesc(
                          "Aucun utilisateur trouvé avec ces informations.",
                          SizeFont.h3.size,
                          3),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: MyTextStyle.lotName(
                              "OK", Colors.black87, SizeFont.h3.size,
                              FontWeight.normal),
                        )
                      ],
                    ),
                  );
                }
              },
              child: MyTextStyle.lotName(
                  "Valider", Colors.black87, SizeFont.h3.size,
                  FontWeight.normal),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> searchNewCSMembreForm(
    BuildContext context,
    String residenceId,
    void Function(User newUser) onUserAdded,
  ) {
    final TextEditingController emailController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Ajouter un membre", Colors.black87, SizeFont.h2.size),
          content: MyTextField(
              hintText: "Mail ou N° utilisateur",
              osbcureText: false,
              padding: 0,
              autofocus: false,
              controller: emailController),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // L'utilisateur annule
              },
              child: MyTextStyle.lotName(
                  "Annuler", Colors.black54, SizeFont.h3.size,
                  FontWeight.normal),
            ),
            TextButton(
              onPressed: () async {
                String input = emailController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Veuillez entrer une adresse email ou un N° utilisateur')),
                  );
                  return; // Ne pas fermer le dialog
                }

                // Recherche utilisateur
                User? user = await FirestoreUserRepository()
                    .getUserWithEmailOrRefApp(input, input)
                    .then((result) => result.when(
                        success: (v) => v, failure: (_) => null));

                if (user != null) {
                  // L'utilisateur existe -> ajout au conseil syndical
                  final result = await FirestoreResidenceRepository()
                      .addCsMember(residenceId, user.uid);
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {
                      onUserAdded(user);
                      Navigator.of(context).pop(input); // Fermer avec succès
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: MyTextStyle.lotName('Ajouté!',
                              Theme.of(context).primaryColor,
                              SizeFont.h1.size),
                          content: MyTextStyle.postDesc(
                            '${user.name} ${user.surname} a été ajouté avec succès !',
                            SizeFont.h3.size,
                            Colors.black54,
                            fontweight: FontWeight.normal,
                            textAlign: TextAlign.justify,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: MyTextStyle.lotName(
                                  "OK", Colors.black87, SizeFont.h3.size,
                                  FontWeight.normal),
                            )
                          ],
                        ),
                      );
                    },
                    failure: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'ajout : $error'),
                        ),
                      );
                    },
                  );
                } else {
                  // Aucun utilisateur trouvé
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: MyTextStyle.lotName(
                          "Erreur", Colors.red[800]!, SizeFont.h2.size),
                      content: MyTextStyle.annonceDesc(
                          "Aucun utilisateur trouvé avec ces informations.",
                          SizeFont.h3.size,
                          3),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: MyTextStyle.lotName(
                              "OK", Colors.black87, SizeFont.h3.size,
                              FontWeight.normal),
                        )
                      ],
                    ),
                  );
                }
              },
              child: MyTextStyle.lotName(
                  "Valider", Colors.black87, SizeFont.h3.size,
                  FontWeight.normal),
            ),
          ],
        );
      },
    );
  }
}
