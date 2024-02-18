import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// class AuthentificationService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   // connexion avec google

// Future <UserCredential> signInWithGoogle () async {
//   // Déclencher le flux d'authentification
//   final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//   // obtenir les détails d'autorisation de la demande
//   final googleAuth = await googleUser!.authentication;
//   // créer un nouvel identifiant
//   final credential = GoogleAuthProvider.credential(
//     accessToken: googleAuth.accessToken,
//     idToken: googleAuth.idToken,
//   );

//   // une fois connecté, renvoyez l'identifiant de l'utilisateur
//   return await _auth.signInWithCredential(credential);
//   }

// // l'état de l'utilisateur

// Stream<User?> get user => _auth.authStateChanges();
// }

class AuthentificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Connexion avec Google
  Future<UserCredential> signInWithGoogle() async {
    // Déclencher le flux d'authentification
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // Vérifier si l'utilisateur a sélectionné un compte Google
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'account-selection-canceled',
        message: 'L\'utilisateur n\'a pas sélectionné de compte Google',
      );
    }

    // obtenir les détails d'autorisation de la demande
    final googleAuth = await googleUser.authentication;

    // créer un nouvel identifiant
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // une fois connecté, renvoyer l'identifiant de l'utilisateur
    return await _auth.signInWithCredential(credential);
  }

  // Création de compte avec les informations Google
  Future<UserCredential> signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'account-selection-canceled',
          message: 'L\'utilisateur n\'a pas sélectionné de compte Google',
        );
      }

      // obtenir les détails d'autorisation de la demande
      final googleAuth = await googleUser.authentication;

      // créer un nouvel identifiant
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Créer un compte avec l'identifiant Google
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'sign-up-error',
        message: 'Erreur lors de la création du compte avec Google: $e',
      );
    }
  }

  Future<void> signOutWithGoogle() async {
    try {
      // Déconnexion de Firebase Auth
      await _auth.signOut();

      // Déconnexion de Google Sign-In
      await _googleSignIn.signOut();
    } catch (e) {
      // Gestion des erreurs
      print('Erreur lors de la déconnexion avec Google: $e');
      throw FirebaseAuthException(
        code: 'sign-out-error',
        message: 'Erreur lors de la déconnexion avec Google: $e',
      );
    }
  }
}
