import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/my_app.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/widgets_controllers/progress_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as Firebase;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthentificationProcess {
  final BuildContext context;
  final FirebaseFirestore firestore;
  final LoadUserController loadUserController;

  AuthentificationProcess({
    required this.context,
    required this.firestore,
    required this.loadUserController,
  });

  final DataBasesUserServices _userDataBases = DataBasesUserServices();

  Future<Firebase.User?> LogInWithGoogle() async {
    try {
      // Charger les données utilisateur
      await loadUserController.loadUserDataGoogle();

      // Écouter les changements d'état de l'authentification
      Firebase.FirebaseAuth.instance.authStateChanges().listen(
          (Firebase.User? user) async {
        if (user != null) {
          // Récupérer les données de l'utilisateur à partir de la base de données
          var userData = await _userDataBases.getUserById(user.uid);

          if (userData?.uid == user.uid) {
            // Si l'utilisateur existe dans la base de données, naviguer vers MyApp
            navigateToMyApp(userData!.uid, firestore);
            return Future.value(user);
          } else {
            loadUserController.handleGoogleSignOut();

            navigateToStep0(user);
            print(
                "Les données utilisateur ne sont pas disponibles dans la base de données.");
            // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
            // Peut-être afficher un message d'erreur ou effectuer une autre action appropriée
            return null;
          }
        } else {
          // Gérer le cas où aucun utilisateur n'est connecté
          // Peut-être afficher un message ou effectuer une autre action appropriée
          print("Aucun utilisateur connecté.");
          return null;
        }
      }, onError: (dynamic error) {
        print(
            'Erreur lors de l\'écoute des changements d\'état d\'authentification : $error');
        // Gérer l'erreur
      });
    } catch (e) {
      // Gérer les erreurs éventuelles
      print("Erreur lors de la connexion : $e");
      // Afficher un message d'erreur ou effectuer une autre action appropriée
      return null;
    }
  }

  Future SignInWithMail(UserCredential userCredential) async {
    User checkUser = userCredential.user!;

    if (checkUser != null) {
      // Récupérer les données de l'utilisateur à partir de la base de données
      var userData = await _userDataBases.getUserById(checkUser.uid);

      if (userData?.uid == checkUser.uid) {
        // Si l'utilisateur existe dans la base de données, naviguer vers MyApp
        navigateToMyApp(userData!.uid, firestore);
        return Future.value(checkUser);
      } else {
        loadUserController.handleGoogleSignOut();

        navigateToStep0(checkUser);
        print(
            "Les données utilisateur ne sont pas disponibles dans la base de données.");
        // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
        // Peut-être afficher un message d'erreur ou effectuer une autre action appropriée
        return null;
      }
    } else {
      // Gérer le cas où aucun utilisateur n'est connecté
      // Peut-être afficher un message ou effectuer une autre action appropriée
      print("Aucun utilisateur connecté.");
      return null;
    }
  }

  void navigateToMyApp(String userID, FirebaseFirestore firestore) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyApp(
          firestore: firestore,
          uid: userID,
        ),
      ),
    );
  }

  void navigateToStep0(Firebase.User user) {
    bool isStep0Present = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/step0') {
        isStep0Present = true;
      }
      return true;
    });
    if (!isStep0Present) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressWidget(newUser: user.uid),
          //Step0(newUser: user.uid),
        ),
      );
    }
  }
}
