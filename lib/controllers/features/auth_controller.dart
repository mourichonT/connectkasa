import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envoie un e-mail de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail({
    required BuildContext context,
    required String email,
  }) async {
    if (email.isEmpty) {
      // Vérifie si l'e-mail est vide
      _showSnackBar(
        context,
        "Veuillez entrer une adresse e-mail.",
        Colors.red,
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _showSnackBar(
        context,
        "Un e-mail de réinitialisation a été envoyé à $email.",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Une erreur s'est produite.";
      if (e.code == 'user-not-found') {
        errorMessage = "Aucun utilisateur trouvé avec cet e-mail.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "L'adresse e-mail est invalide.";
      }
      _showSnackBar(context, errorMessage, Colors.red);
    } catch (e) {
      // Gère d'autres types d'erreurs
      _showSnackBar(context, "Erreur : ${e.toString()}", Colors.red);
    }
  }

  /// Affiche un SnackBar pour les messages
  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
