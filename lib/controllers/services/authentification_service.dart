import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthentificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();



  // connexion avec google

Future <UserCredential> signInWithGoogle () async {
  // Déclencher le flux d'authentification
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  // obtenir les détails d'autorisation de la demande
  final googleAuth = await googleUser!.authentication;
  // créer un nouvel identifiant
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  // une fois connecté, renvoyez l'identifiant de l'utilisateur
  return await _auth.signInWithCredential(credential);
  }


// l'état de l'utilisateur

Stream<User?> get user => _auth.authStateChanges();
}