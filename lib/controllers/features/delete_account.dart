import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/vues/pages_vues/login_page_view.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
          const Center(child: CircularProgressIndicator()),
    );

    try {
      await DataBasesUserServices.deleteAccountCompletely(uid);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPageView(firestore: FirebaseFirestore.instance),
        ),
        (route) => false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader

      if (e.code == 'requires-recent-login') {
        final reauthenticated =
            await _reauthenticate(context: context, email: email);
        if (reauthenticated) {
          await execute(
              context: context,
              uid: uid,
              email: email); // relance la suppression une fois reconnecté
        }
        return;
      }

      _showErrorDialog(
          context, 'Erreur lors de la suppression du compte : ${e.message}');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader
      _showErrorDialog(context,
          'Une erreur est survenue lors de la suppression du compte : $e');
    }
  }

  /// Firebase exige une connexion récente pour autoriser une suppression de
  /// compte. Si la session est trop ancienne, on redemande les identifiants
  /// (mot de passe ou Google selon le fournisseur utilisé) avant de relancer
  /// la suppression.
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
