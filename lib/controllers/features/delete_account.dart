import 'package:connect_kasa/vues/pages_vues/login_page_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connect_kasa/vues/widget_view/components/app_loader.dart';

/// Levée quand l'utilisateur annule la procédure (dialogue de mot de passe
/// fermé, ou Google Sign-In annulé) pendant la ré-authentification.
/// Signale qu'il ne faut rien supprimer, sans afficher d'erreur.
class _DeletionCancelled implements Exception {}

class DeleteAccount {
  static Future<void> execute({
    required BuildContext context,
    required String uid,
    required String email,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: AppLoader()),
    );

    try {
      // Le compte Firebase Auth doit être supprimé EN PREMIER. Tant que
      // cette étape n'est pas confirmée, on ne touche à aucune donnée : si
      // l'utilisateur annule la ré-authentification, son compte et ses
      // données restent intacts.
      //
      // La purge des données Firestore/Storage n'est plus faite ici : une
      // fois le compte Auth supprimé, le client n'est plus authentifié et ne
      // peut donc plus satisfaire firestore.rules pour ces écritures. Elle
      // est déclenchée automatiquement côté serveur (Cloud Function
      // cleanupUserData, functions/index.js, SDK Admin qui contourne les
      // règles) dès que la suppression du compte Auth est confirmée.
      await _deleteAuthAccount(context: context, email: email);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPageView(firestore: FirebaseFirestore.instance),
        ),
        (route) => false,
      );
    } on _DeletionCancelled {
      // Ré-authentification annulée par l'utilisateur : rien n'a été
      // supprimé, on referme juste le loader.
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader
      _showErrorDialog(context,
          'Une erreur est survenue lors de la suppression du compte : $e');
    }
  }

  /// Supprime le compte Firebase Auth courant. Si la session est trop
  /// ancienne (requires-recent-login), redemande les identifiants et
  /// retente une seule fois. Ne supprime jamais de données Firestore.
  static Future<void> _deleteAuthAccount({
    required BuildContext context,
    required String email,
  }) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await currentUser.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;

      final reauthenticated =
          await _reauthenticate(context: context, email: email);
      if (!reauthenticated) {
        throw _DeletionCancelled();
      }
      await currentUser.delete(); // relance une fois reconnecté
    }
  }

  /// Firebase exige une connexion récente pour autoriser une suppression de
  /// compte. Si la session est trop ancienne, on redemande les identifiants
  /// (mot de passe ou Google selon le fournisseur utilisé).
  static Future<bool> _reauthenticate({
    required BuildContext context,
    required String email,
  }) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final isGoogleUser = currentUser.providerData
        .any((info) => info.providerId == 'google.com');

    try {
      if (isGoogleUser) {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return false; // annulé par l'utilisateur

        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await currentUser.reauthenticateWithCredential(credential);
      } else {
        final password = await _askPassword(context);
        if (password == null || password.isEmpty) return false;

        final credential = firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await currentUser.reauthenticateWithCredential(credential);
      }
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      _showErrorDialog(context,
          'La ré-authentification a échoué, la suppression du compte a été annulée.');
      return false;
    }
  }

  static Future<String?> _askPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmez votre mot de passe'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirmer'),
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
