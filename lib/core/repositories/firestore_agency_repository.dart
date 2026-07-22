import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/services/firestore_paths.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/agency_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/agency_dept.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';
import 'package:konodal/models/pages_models/user.dart';

const _agentUidFieldByService = {
  'serviceSyndic': 'serviceSyndicAgentUids',
  'geranceLocative': 'geranceLocativeAgentUids',
};

Agent _agentFromUser(User user) => Agent(
      uid: user.uid,
      nameAgent: user.name,
      surnameAgent: user.surname,
      mail: user.email,
      phone: user.phone,
    );

class FirestoreAgencyRepository implements IAgencyRepository {
  final FirebaseFirestore _firestore;
  final FirestoreUserRepository _userRepository;

  FirestoreAgencyRepository({
    FirebaseFirestore? firestore,
    FirestoreUserRepository? userRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userRepository =
            userRepository ?? FirestoreUserRepository(firestore: firestore);

  @override
  Future<Result<List<Agency>>> searchByEmail(
    String emailPart, {
    required String serviceType,
  }) async {
    if (emailPart.isEmpty) return const Result.success([]);

    try {
      // Recherche par sous-chaîne (n'importe où dans le mail, pas seulement
      // en préfixe) parmi les comptes "agent"/"agence" (users/{uid}) -
      // Firestore ne fait pas de recherche par sous-chaîne nativement, donc
      // on filtre côté client après récupération, comme pour
      // rechercheFirestore (recherche de résidence à l'inscription).
      final usersSnapshot = await _firestore
          .collection('users')
          .where('accountType', whereIn: ['agent', 'agence'])
          .get();

      final matchingUsers = usersSnapshot.docs
          .map((doc) => User.fromMap(doc.data()))
          .where((user) => user.email.toLowerCase().contains(
                emailPart.toLowerCase(),
              ))
          .toList();

      if (matchingUsers.isEmpty) return const Result.success([]);

      final agentUidField = _agentUidFieldByService[serviceType]!;

      // Une personne (agent ou agence) par ligne de résultat, pas une
      // gérance entière : chaque uid trouvé est reversé vers SA/ses
      // gérance(s) via <serviceType>AgentUids (array-contains).
      final results = <Agency>[];
      for (final user in matchingUsers) {
        final geranceSnapshot = await _firestore
            .collection(FirestorePaths.gerance)
            .where(agentUidField, arrayContains: user.uid)
            .get();

        for (final geranceDoc in geranceSnapshot.docs) {
          final geranceData = geranceDoc.data();
          final address = Address.fromJson(geranceData['address']);
          results.add(Agency(
            id: geranceDoc.id,
            name: geranceData['name'] ?? '',
            city: address.city,
            street: address.street,
            zipCode: address.zipCode,
            codeQualite: address.codeQualite,
            syndic: AgencyDept(
              agents: [_agentFromUser(user)],
              mail: user.email,
              phone: user.phone,
            ),
          ));
        }
      }
      return Result.success(results);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Agency?>> resolveRef(GeranceRef ref) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.gerance)
          .doc(ref.geranceId)
          .get();
      if (!doc.exists) return const Result.success(null);

      final data = doc.data()!;
      final services = data['services'] as Map<String, dynamic>?;
      final serviceData = services?[ref.serviceType] as Map<String, dynamic>?;
      if (serviceData == null) return const Result.success(null);

      String mail = serviceData['mail'] ?? '';
      String phone = serviceData['phone'] ?? '';
      final agents = <Agent>[];

      // ref.agentUid absent (ref legacy, ou choix "cabinet" générique sans
      // agent précis) : on retombe sur le premier uid de
      // <serviceType>AgentUids plutôt que sur le mail générique du service -
      // sinon toute résidence dont le syndic a été choisi sans agent précis
      // (le cas de TOUTES les résidences existantes à ce jour) afficherait un
      // contact générique potentiellement incomplet (mail/téléphone vides)
      // au lieu d'un vrai compte agent/agence.
      final agentUids =
          (data[_agentUidFieldByService[ref.serviceType]] as List<dynamic>?)
              ?.cast<String>() ??
              [];
      final resolvedUid =
          ref.agentUid ?? (agentUids.isNotEmpty ? agentUids.first : null);

      if (resolvedUid != null) {
        final userResult = await _userRepository.getUserById(resolvedUid);
        userResult.when(
          success: (user) {
            agents.add(_agentFromUser(user));
            mail = user.email;
            phone = user.phone;
          },
          failure: (_) {}, // compte supprimé entretemps : fallback service
        );
      }

      final address = Address.fromJson(data['address']);
      return Result.success(Agency(
        id: ref.geranceId,
        name: data['name'] ?? '',
        city: address.city,
        street: address.street,
        zipCode: address.zipCode,
        codeQualite: address.codeQualite,
        syndic: AgencyDept(
          agents: agents,
          mail: mail,
          phone: phone,
        ),
      ));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
