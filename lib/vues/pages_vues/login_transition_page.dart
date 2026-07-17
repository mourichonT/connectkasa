import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/load_prefered_data.dart';
import 'package:konodal/controllers/handlers/api/flutter_api.dart';
import 'package:konodal/controllers/handlers/progress_widget.dart';
import 'package:konodal/controllers/pages_controllers/my_app.dart';
import 'package:konodal/controllers/providers/color_provider.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/providers/post_providers.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/pages_vues/no_approval_page.dart';
import 'package:konodal/vues/pages_vues/no_lot/no_lot_page.dart';
import 'package:konodal/vues/pages_vues/wrong_account_type_page.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page affichée immédiatement après une authentification Firebase
/// réussie (Google ou email), AVANT la recherche Firestore de
/// l'utilisateur (AuthentificationProcess.fluttLogInWithGoogle/
/// signInWithMail poussaient auparavant cette page seulement APRÈS
/// cette recherche + la vérification d'approbation - laissant l'écran
/// de connexion sans retour visuel pendant tout ce temps). La
/// recherche et la décision de destination (accueil / en attente
/// d'approbation / inscription) se font maintenant ici, pendant que le
/// loader tourne, puis la page se remplace elle-même par la bonne
/// destination.
///
/// Pour la connexion Google, [googleSignInTask] est fourni à la place
/// de [uid] : la page est poussée AVANT même l'ouverture du sélecteur
/// de compte Google, pour que tout le flux (sélection + échange de
/// jetons Google/Firebase, chacun un aller-retour réseau) se déroule
/// derrière le loader plutôt que de laisser l'écran de connexion figé
/// pendant ce temps.
class LoginTransitionPage extends ConsumerStatefulWidget {
  final FirebaseFirestore firestore;
  final String? uid;
  final String? emailUser;
  final Future<Result<UserCredential>> Function()? googleSignInTask;

  const LoginTransitionPage({
    super.key,
    required this.firestore,
    this.uid,
    this.emailUser,
    this.googleSignInTask,
  }) : assert(uid != null || googleSignInTask != null);

  @override
  ConsumerState<LoginTransitionPage> createState() =>
      _LoginTransitionPageState();
}

class _LoginTransitionPageState extends ConsumerState<LoginTransitionPage> {
  final IUserRepository _userRepository = FirestoreUserRepository();
  final ILotRepository _lotRepository = FirestoreLotRepository();
  late String _uid;
  String? _emailUser;

  @override
  void initState() {
    super.initState();
    if (widget.googleSignInTask != null) {
      _runGoogleSignIn();
    } else {
      _uid = widget.uid!;
      _emailUser = widget.emailUser;
      _resolveDestination();
    }
  }

  Future<void> _runGoogleSignIn() async {
    final result = await widget.googleSignInTask!();
    if (!mounted) return;

    result.when(
      success: (credential) {
        _uid = credential.user!.uid;
        _emailUser = credential.user!.email ?? widget.emailUser;
        appLog("✅ Compte Google connecté : UID=$_uid | EMAIL=$_emailUser");
        _resolveDestination();
      },
      failure: (error) {
        if (error is CancelledException) {
          // Sélection de compte annulée par l'utilisateur : retour
          // simple à l'écran de connexion, sans message d'erreur.
          Navigator.of(context).pop();
        } else {
          appLog("❌ Erreur lors de la connexion Google : $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur de connexion, réessayez : $error")),
          );
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _initUserFcmToken(String uid) {
    FirebaseApi.getToken().then((value) {
      if (value != null) {
        _userRepository.updateFcmToken(uid: uid, token: value);
      }
    });
  }

  /// Reproduit exactement le comportement de l'ancien
  /// AuthentificationProcess.navigateToStep0 : si un ProgressWidget
  /// (route nommée '/step0') est déjà présent dans la pile (ex. retour
  /// en arrière pendant une inscription interrompue), on y revient au
  /// lieu d'en pousser un nouveau - évite de dupliquer le minuteur de
  /// suppression de compte que ProgressWidget démarre à la création.
  void _goToStep0() {
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProgressWidget(
            userId: _uid,
            emailUser: _emailUser ?? FirebaseAuth.instance.currentUser?.email,
            providerId: providerId,
          ),
        ),
      );
    }
  }

  /// Reproduit la résolution du lot préféré de MyNavBar._initializeLot
  /// (cache SharedPreferences croisé avec la liste fraîche de lots
  /// approuvés, repli sur le premier lot sinon) - fait ici pour connaître
  /// la résidence à précharger AVANT de naviguer vers MyNavBar, qui reçoit
  /// ensuite ce résultat tout fait (initialPreferredLot) au lieu de le
  /// recalculer.
  Future<Lot> _resolvePreferredLot(List<Lot> approvedLots) async {
    Lot? cachedPreferedLot;
    try {
      cachedPreferedLot = await LoadPreferedData().loadPreferedLot(_uid);
    } catch (e) {
      appLog("Lot préféré en cache illisible (format obsolète ?), ignoré : $e");
      cachedPreferedLot = null;
    }

    if (cachedPreferedLot != null) {
      for (final lot in approvedLots) {
        if (lot.id == cachedPreferedLot.id) return lot;
      }
    }
    return approvedLots.first;
  }

  Future<void> _resolveDestination() async {
    final result = await _userRepository.getUserById(_uid);
    if (!mounted) return;

    result.when(
      success: (userData) async {
        // Cette app est l'interface résident uniquement : un compte
        // 'professionnel'/'superAdmin' (créé hors-app, futur backoffice
        // web) n'a pas sa place ici.
        if (userData.accountType != 'utilisateur') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WrongAccountTypePage()),
          );
          return;
        }

        if (!userData.isApproved) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  NoApprovalPage(rejectionReason: userData.rejectionReason),
            ),
          );
          return;
        }

        // Un lot nouvellement rattaché reste bloqué tant qu'une personne n'a
        // pas revérifié les documents déposés (isApprovedLot, cf.
        // AttachExistingLotPage/sync_lot_approval) : on ne considère donc que
        // les lots déjà approuvés pour décider de l'accès à l'app.
        final lots = await _lotRepository.getLotByIdUser(_uid).then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));
        if (!mounted) return;

        // Même filtre que MyNavBar._fetchApprovedLots : calculé ici pour
        // être transmis tel quel à MyNavBar (initialLots), qui refaisait
        // sinon la même requête getLotByIdUser juste après avoir atterri
        // sur cette page - un aller-retour Firestore redondant.
        final approvedLots = lots
            .where((lot) =>
                lot.userLotDetails['isApprovedLot'] == true &&
                !lot.groupedWithParent)
            .toList();

        _initUserFcmToken(_uid);
        if (approvedLots.isNotEmpty) {
          final preferredLot = await _resolvePreferredLot(approvedLots);
          if (!mounted) return;

          // Préchauffe le cache du provider avec la 1re page de posts de la
          // résidence pendant que ce loader est encore affiché : HomeView
          // (derrière MyNavBar) l'affichera donc directement, sans son
          // propre spinner de chargement. Best-effort : un échec ici ne
          // doit pas empêcher la navigation, HomeView réessaiera lui-même.
          if (preferredLot.residenceId.isNotEmpty) {
            try {
              await ref.read(
                  postsByResidenceProvider(preferredLot.residenceId).future);
            } catch (e) {
              appLog("Préchargement des posts échoué (non bloquant) : $e");
            }
            if (!mounted) return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MyApp2(
                firestore: widget.firestore,
                uid: _uid,
                initialLots: approvedLots,
                initialPreferredLot: preferredLot,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => NoLotPage(uid: _uid)),
          );
        }
      },
      failure: (error) {
        if (error is NotFoundException) {
          // Compte jamais encore enregistré dans Firestore : nouvel
          // utilisateur, pas une erreur.
          appLog(
              "🚨 Utilisateur non trouvé dans Firestore → Redirection Step0");
          _goToStep0();
        } else {
          // Vraie erreur (réseau, permission...) : surtout ne pas
          // envoyer un utilisateur existant dans le flux d'inscription
          // sur un simple aléa réseau - on revient à l'écran de
          // connexion avec un message clair.
          appLog("❌ Erreur lors de la résolution post-connexion : $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur de connexion, réessayez : $error"),
            ),
          );
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      // Couleur par défaut de l'app, pas celle (éventuellement obsolète)
      // du dernier lot chargé dans ColorProvider : à ce stade on ne sait
      // pas encore quel lot appartient à l'utilisateur qui se connecte.
      body: Center(
        child: AppLoader(size: 120, color: ColorProvider.defaultColor),
      ),
    );
  }
}
