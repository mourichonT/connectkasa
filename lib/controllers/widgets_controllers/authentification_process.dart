import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/pages_controllers/my_app.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/vues/pages_vues/no_approval_page.dart';
import 'package:connect_kasa/controllers/handlers/progress_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as Firebase;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<Firebase.User?> fluttLogInWithGoogle() async {
    try {
      // 1. Déconnexion de Firebase et Google
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn()
          .signOut(); // <- Assure-toi d'importer 'google_sign_in'

      // 2. Lancer l'authentification avec Google
      await loadUserController
          .loadUserDataGoogle(); // <- fait la connexion Google et l'auth avec Firebase

      // 3. Récupérer l'utilisateur connecté via Firebase
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("Aucun utilisateur Google authentifié.");
        return null;
      }

      final uid = user.uid;
      final email = user.email;

      print("✅ Compte Google connecté : UID=$uid | EMAIL=$email");

      // 4. Chercher dans Firestore si l'utilisateur existe
      final userData = await DataBasesUserServices.getUserById(uid);

      if (userData != null && userData.approved == true) {
        navigateToMyApp(uid, firestore);
        return user;
      } else if (userData != null && userData.approved == false) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoApprovalPage(),
          ),
        );
        return null;
      } else {
        // L'utilisateur n'existe pas encore dans Firestore
        print("🚨 Utilisateur non trouvé dans Firestore → Redirection Step0");

        navigateToStep0(user);
        return null;
      }
    } catch (e) {
      print("❌ Erreur lors de la connexion Google : $e");
      return null;
    }
  }

  // Future<Firebase.User?> fluttLogInWithApple() async {
  //   try {
  //     // Demander les informations d'authentification Apple
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //       webAuthenticationOptions: WebAuthenticationOptions(
  //         clientId: 'com.yourcompany.yourapp', // Change ça par ton clientId
  //         redirectUri: kIsWeb
  //             ? Uri.parse('https://${window.location.host}/')
  //             : Uri.parse('https://your-redirect-uri.com/callback'),
  //       ),
  //     );

  //     // Affiche les informations d'authentification récupérées
  //     print(credential);

  //     // Créer un OAuthCredential Firebase à partir des informations d'Apple
  //     final oauthCredential = Firebase.OAuthProvider("apple.com").credential(
  //       idToken: credential.identityToken,
  //       accessToken: credential.authorizationCode,
  //     );

  //     // Authentifier l'utilisateur avec Firebase
  //     final userCredential = await Firebase.FirebaseAuth.instance
  //         .signInWithCredential(oauthCredential);

  //     final user = userCredential.user;

  //     if (user != null) {
  //       // Charger les données utilisateur à partir de la base de données
  //       var userData = await _userDataBases.getUserById(user.uid);

  //       if (userData?.uid == user.uid) {
  //         // Si l'utilisateur existe dans la base de données, naviguer vers MyApp
  //         navigateToMyApp(userData!.uid, firestore);
  //         return Future.value(user);
  //       } else {
  //         loadUserController.handleGoogleSignOut();
  //         navigateToStep0(user);
  //         print("Les données utilisateur ne sont pas disponibles dans la base de données.");
  //         // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
  //         return null;
  //       }
  //     } else {
  //       print("Aucun utilisateur connecté.");
  //       return null;
  //     }
  //   } catch (e) {
  //     // Gérer les erreurs éventuelles
  //     print("Erreur lors de la connexion avec Apple : $e");
  //     return null;
  //   }
  // }

  // Méthode de connexion avec Microsoft
  // Future<Firebase.User?> fluttLogInWithMicrosoft() async {
  //   try {
  //     // Charger les données utilisateur
  //     final OAuthProvider provider = OAuthProvider("microsoft.com");
  //     provider.setCustomParameters({"tenant":"4c71c353-ccfc-44a4-8933-16fafd42ee8b" });

  //     await  Firebase.FirebaseAuth.instance.signInWithProvider(provider);
  //     // Écouter les changements d'état de l'authentification
  //     Firebase.FirebaseAuth.instance.authStateChanges().listen(
  //         (Firebase.User? user) async {
  //       if (user != null) {
  //         // Récupérer les données de l'utilisateur à partir de la base de données
  //         var userData = await _userDataBases.getUserById(user.uid);

  //         if (userData?.uid == user.uid) {
  //           // Si l'utilisateur existe dans la base de données, naviguer vers MyApp
  //           navigateToMyApp(userData!.uid, firestore);
  //           return Future.value(user);
  //         } else {
  //           loadUserController.handleGoogleSignOut();

  //           navigateToStep0(user);
  //           print(
  //               "Les données utilisateur ne sont pas disponibles dans la base de données.");
  //           // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
  //           // Peut-être afficher un message d'erreur ou effectuer une autre action appropriée
  //           return null;
  //         }
  //       } else {
  //         // Gérer le cas où aucun utilisateur n'est connecté
  //         // Peut-être afficher un message ou effectuer une autre action appropriée
  //         print("Aucun utilisateur connecté.");
  //         return null;
  //       }
  //     }, onError: (dynamic error) {
  //       print(
  //           'Erreur lors de l\'écoute des changements d\'état d\'authentification : $error');
  //       // Gérer l'erreur
  //     });
  //   } catch (e) {
  //     // Gérer les erreurs éventuelles
  //     print("Erreur lors de la connexion : $e");
  //     // Afficher un message d'erreur ou effectuer une autre action appropriée
  //     return null;
  //   }
  // }

  Future SignInWithMail(UserCredential userCredential) async {
    User checkUser = userCredential.user!;

    // Récupérer les données de l'utilisateur à partir de la base de données
    var userData = await DataBasesUserServices.getUserById(checkUser.uid);

    if (userData?.uid == checkUser.uid && userData?.approved == true) {
      // Si l'utilisateur existe dans la base de données, naviguer vers MyApp
      navigateToMyApp(userData!.uid, firestore);
      return Future.value(checkUser);
    } else if (userData?.uid == checkUser.uid && userData?.approved == false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoApprovalPage(),
        ),
      );
    } else {
      loadUserController.handleGoogleSignOut();

      navigateToStep0(checkUser);
      print(
          "Les données utilisateur ne sont pas disponibles dans la base de données.");
      // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
      // Peut-être afficher un message d'erreur ou effectuer une autre action appropriée
      return null;
    }
  }

  void navigateToMyApp(String userID, FirebaseFirestore firestore) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyApp2(
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
      final providerData = FirebaseAuth.instance.currentUser?.providerData;
      final providerId = (providerData != null && providerData.isNotEmpty)
          ? providerData.first.providerId
          : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressWidget(
            userId: user.uid,
            emailUser: user.email,
            providerId: providerId,
          ),
        ),
      );
    }
  }
}
