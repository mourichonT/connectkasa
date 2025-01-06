import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthentificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterAppAuth _appAuth = FlutterAppAuth();

Future<UserCredential> signInWithMicrosoft() async {
    try {
      // Paramètres de configuration OAuth Microsoft
      final AuthorizationTokenRequest request = AuthorizationTokenRequest(
        'YOUR_CLIENT_ID', // ID de votre application Microsoft
        'YOUR_REDIRECT_URI', // URI de redirection configurée dans Azure
        discoveryUrl: 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email', 'User.Read'],
      );

      // Authentification Microsoft
      final AuthorizationTokenResponse result = await _appAuth.authorizeAndExchangeCode(request);

      // Création des informations d'identification Firebase avec le token Microsoft
      final OAuthCredential microsoftCredential = OAuthProvider("microsoft.com").credential(
        accessToken: result.accessToken,
        idToken: result.idToken,
      );

      // Connexion à Firebase avec les identifiants Microsoft
      return await _auth.signInWithCredential(microsoftCredential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'microsoft-sign-in-error',
        message: 'Erreur lors de la connexion avec Microsoft: $e',
      );
    }
  }
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
