import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/core/repositories/auth_repository.dart';
import 'package:connect_kasa/core/repositories/firebase_auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:connect_kasa/core/utils/app_logger.dart';

class LoadUserController {
  final IAuthRepository _authRepository = FirebaseAuthRepository();
  firebase_auth.UserCredential? user;

  Future<void> registerUserInFirestore(firebase_auth.User user) async {
    FirebaseFirestore.instance.collection("User").doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? "N/A",
      'email': user.email ?? "N/A",
      'createdDate': Timestamp.now(),
      'profilPic': user.photoURL ?? "",

      // Ajoutez d'autres champs nécessaires ici
    });
  }

  Future<String> loadUserDataGoogle() async {
    final result = await _authRepository.signUpWithGoogle();
    return result.when(
      success: (credential) {
        user = credential;
        return credential.user!.uid;
      },
      failure: (error) => throw error,
    );
  }

//    Future<String> loadUserDataMicrosoft() async {
//     user = await authService.signInWithMicrosoft();
//     String iud = user!.user!.uid;

//     return iud;
//   }
//  Future<void> handleMicrosoftSignOut() async {
//     try {
//       await authService.signOutWithGoogle();
//     } catch (e) {
//     }
//   }
  // Utilisation de la variable user déclarée au niveau de la classe.
  Future<void> handleGoogleSignOut() async {
    final result = await _authRepository.signOutWithGoogle();
    result.when(
      success: (_) {},
      failure: (error) =>
          appLog('Erreur lors de la déconnexion avec Google: $error'),
    );
  }

  static Future<String> getUserEmail(String uid) async {
    firebase_auth.User? firebaseUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid == uid) {
      return firebaseUser.email ?? "";
    } else {
      // Si l'utilisateur actuel ne correspond pas à l'uid, récupérez l'utilisateur via l'API Admin (nécessite un backend)
      return ""; // Gérer en fonction de votre logique
    }
  }
}
