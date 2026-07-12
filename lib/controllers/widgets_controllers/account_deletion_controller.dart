import 'package:konodal/controllers/features/delete_account.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class AccountDeletionController {
  final BuildContext context;
  final String uid;
  final String email;

  AccountDeletionController({
    required this.context,
    required this.uid,
    required this.email,
  });

  Future<void> confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
                    "Supprimer mon compte", Colors.black87, SizeFont.h1.size),
          content: MyTextStyle.annonceDesc('Cette action est définitive. Votre profil, vos documents, vos lots et vos demandes seront supprimés et vous perdrez l\'accès à votre compte. Voulez-vous vraiment continuer ?', SizeFont.h3.size,5),
          actions: <Widget>[
            TextButton(
              child:  MyTextStyle.lotName(
                    "Annuler", Colors.black45, SizeFont.h3.size, FontWeight.normal),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child:  MyTextStyle.lotName(
                    "Supprimer", Colors.red, SizeFont.h3.size, FontWeight.normal),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;
    await DeleteAccount.execute(context: context, uid: uid, email: email);
  }
}
