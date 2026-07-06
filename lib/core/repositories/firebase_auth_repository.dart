import 'package:connect_kasa/core/errors/app_exceptions.dart';
import 'package:connect_kasa/core/repositories/auth_repository.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<Result<UserCredential>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return Result.failure(
            const CancelledException('Sélection de compte Google annulée'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return Result.success(userCredential);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<UserCredential>> signUpWithGoogle() {
    // Même flux OAuth que signInWithGoogle : Firebase crée le compte
    // automatiquement s'il n'existe pas encore.
    return signInWithGoogle();
  }

  @override
  Future<Result<void>> signOutWithGoogle() async {
    try {
      await _auth.signOut();

      // Timeout défensif : sur un environnement où Google Play Services
      // répond mal (émulateur sans image système "Google Play", coupure
      // réseau...), cet appel peut ne jamais se résoudre et geler
      // indéfiniment l'app au moment de la déconnexion.
      await _googleSignIn.signOut().timeout(const Duration(seconds: 5));

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
