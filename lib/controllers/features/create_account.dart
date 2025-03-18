import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/widgets_controllers/progress_widget.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateAccountController {
  /// Méthode principale pour créer un compte
  static Future<void> createAccount(
    BuildContext context,
    String email,
    String password,
    String confirmPassword,
    FirebaseFirestore firestore,
  ) async {
    // Vérification des champs vides
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar(context, "Veuillez remplir tous les champs.");
      return;
    }

    // Vérifiez si les mots de passe correspondent
    if (!_confirmPassword(password, confirmPassword)) {
      _showSnackbar(context, "Les mots de passe ne correspondent pas.");
      return;
    }

    // Vérifiez la complexité du mot de passe
    if (!_isPasswordStrong(password)) {
      _showSnackbar(
        context,
        "Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial.",
      );
      return;
    }

    try {
      // Création de l'utilisateur avec email et mot de passe
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Initialisation de l'objet UserTemp
      UserTemp newUser = UserTemp(
        email: email,
        createdDate: Timestamp.now(),
        name: "", // Remplacez par une saisie réelle
        surname: "", // Remplacez par une saisie réelle
        pseudo: "", // Remplacez par une saisie réelle
        uid: userCredential.user!.uid,
        approved: false,
        // statutResident: "", // Remplacez par une logique réelle
        typeLot: "",
        birthday: Timestamp.now(), // Remplacez par une logique réelle
        // compagnyBuy: false, // Remplacez par une logique réelle
      );

      // Ajout des données utilisateur dans Firestore
      await firestore.collection('User').doc(userCredential.user!.uid).set(
            newUser.toMap(),
          );

      // Affichage d'un message de succès et navigation
      _showSnackbar(context, "Compte créé avec succès !");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressWidget(
            userId: userCredential.user!.uid,
            emailUser: email,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs spécifiques à Firebase Auth
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Cet email est déjà utilisé.";
          break;
        case 'invalid-email':
          errorMessage = "L'adresse email est invalide.";
          break;
        case 'weak-password':
          errorMessage = "Le mot de passe est trop faible.";
          break;
        default:
          errorMessage = "Une erreur est survenue. Veuillez réessayer.";
      }
      _showSnackbar(context, errorMessage);
    } catch (e) {
      // Gestion des erreurs inattendues
      _showSnackbar(context, "Erreur inattendue : ${e.toString()}");
    }
  }

  /// Vérifie la complexité du mot de passe
  static bool _isPasswordStrong(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$',
    );
    return regex.hasMatch(password);
  }

  /// Vérifie si les mots de passe correspondent
  static bool _confirmPassword(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  /// Affiche une Snackbar avec un message personnalisé
  static void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
