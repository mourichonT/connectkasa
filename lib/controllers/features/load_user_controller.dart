import 'package:connect_kasa/controllers/services/authentification_service.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoadUserController {
  AuthentificationService authService = AuthentificationService();
  DataBasesUserServices dataBasesUserServices = DataBasesUserServices();
  UserCredential? user;

  Future<String> loadUserDataGoogle() async {
    user = await authService.signUpWithGoogle();
    String iud = user!.user!.uid;

    return iud;
  }

  // Utilisation de la variable user déclarée au niveau de la classe.
  Future<void> handleGoogleSignOut() async {
    try {
      await authService.signOutWithGoogle();
    } catch (e) {
      print('Erreur lors de la déconnexion avec Google: $e');
    }
  }
}
