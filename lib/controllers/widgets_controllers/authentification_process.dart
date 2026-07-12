import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/handlers/api/flutter_api.dart';
import 'package:connect_kasa/core/errors/app_exceptions.dart';
import 'package:connect_kasa/core/repositories/user_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_user_repository.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/vues/pages_vues/no_approval_page.dart';
import 'package:connect_kasa/vues/pages_vues/login_transition_page.dart';
import 'package:connect_kasa/controllers/handlers/progress_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as Firebase;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connect_kasa/core/utils/app_logger.dart';

class AuthentificationProcess {
  final BuildContext context;
  final FirebaseFirestore firestore;
  final LoadUserController loadUserController;

  AuthentificationProcess({
    required this.context,
    required this.firestore,
    required this.loadUserController,
  });

  final IUserRepository _userDataBases = FirestoreUserRepository();

  /// Ouvre le sélecteur de compte Google directement (pas de loader
  /// avant : on ne veut pas de flash d'écran entre le clic et la
  /// modal). Le loader (LoginTransitionPage) n'est poussé qu'une fois
  /// un compte choisi, pour couvrir le seul aller-retour réseau qui
  /// restait visible sur l'écran de connexion : l'échange des jetons
  /// Google contre des identifiants Firebase.
  Future<void> fluttLogInWithGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        appLog("Connexion Google annulée par l'utilisateur.");
        return;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginTransitionPage(
            firestore: firestore,
            googleSignInTask: () => _completeGoogleSignIn(googleUser),
          ),
        ),
      );
    } catch (e) {
      appLog("❌ Erreur lors de la connexion Google : $e");
    }
  }

  Future<Result<UserCredential>> _completeGoogleSignIn(
      GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return Result.success(userCredential);
    } catch (e) {
      return Result.failure(AppException.from(e));
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
  //     appLog(credential);

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
  //         appLog("Les données utilisateur ne sont pas disponibles dans la base de données.");
  //         // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
  //         return null;
  //       }
  //     } else {
  //       appLog("Aucun utilisateur connecté.");
  //       return null;
  //     }
  //   } catch (e) {
  //     // Gérer les erreurs éventuelles
  //     appLog("Erreur lors de la connexion avec Apple : $e");
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
  //           appLog(
  //               "Les données utilisateur ne sont pas disponibles dans la base de données.");
  //           // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
  //           // Peut-être afficher un message d'erreur ou effectuer une autre action appropriée
  //           return null;
  //         }
  //       } else {
  //         // Gérer le cas où aucun utilisateur n'est connecté
  //         // Peut-être afficher un message ou effectuer une autre action appropriée
  //         appLog("Aucun utilisateur connecté.");
  //         return null;
  //       }
  //     }, onError: (dynamic error) {
  //       appLog(
  //           'Erreur lors de l\'écoute des changements d\'état d\'authentification : $error');
  //       // Gérer l'erreur
  //     });
  //   } catch (e) {
  //     // Gérer les erreurs éventuelles
  //     appLog("Erreur lors de la connexion : $e");
  //     // Afficher un message d'erreur ou effectuer une autre action appropriée
  //     return null;
  //   }
  // }

  Future SignInWithMail(UserCredential userCredential) async {
    User checkUser = userCredential.user!;

    // Récupérer les données de l'utilisateur à partir de la base de données
    var userData = await _userDataBases
        .getUserById(checkUser.uid)
        .then((result) => result.when(success: (v) => v, failure: (_) => null));

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
      appLog(
          "Les données utilisateur ne sont pas disponibles dans la base de données.");
      // Gérer le cas où les données utilisateur ne sont pas disponibles dans la base de données
      // Peut-être afficher un message d'erreur ou effectuer une autre action appropriée
      return null;
    }
  }

  void navigateToMyApp(String userID, FirebaseFirestore firestore,
      {String? email}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginTransitionPage(
          firestore: firestore,
          uid: userID,
          emailUser: email,
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

  void initUserFcmToken(uid) async {
    FirebaseApi.getToken().then((value) {
      if (value != null) {
        _userDataBases.updateFcmToken(uid: uid, token: value);
      }
    });
  }
}
