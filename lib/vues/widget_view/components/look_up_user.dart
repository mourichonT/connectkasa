import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/components/my_text_fied.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';

class LookUpUser {
  static Future<String?> searchUserForm(
      BuildContext context, DemandeLoc demande) {
    final TextEditingController emailController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Destinataire'),
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
              child: Text('Annuler'),
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
                User? user =
                    await DataBasesUserServices.getUserWithEmailOrRefApp(
                        input, input);

                if (user != null) {
                  // L'utilisateur existe -> partage du fichier
                  await DataBasesUserServices.shareFile(
                      demande, user.uid); // ou autre clé selon ton modèle User
                  Navigator.of(context).pop(input); // Fermer avec succès
                  print('DemandeLoc envoyée avec succès !');
                } else {
                  // Aucun utilisateur trouvé
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Erreur'),
                      content: Text(
                          "Aucun utilisateur trouvé avec ces informations."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        )
                      ],
                    ),
                  );
                }
              },
              child: Text('Valider'),
            ),
          ],
        );
      },
    );
  }
}
