import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/dependent_entry.dart';
import 'package:konodal/controllers/features/income_entry.dart';
import 'package:konodal/controllers/features/job_entry.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/conjoint_info.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:intl/intl.dart';

// Assure-toi que JobEntry est bien défini quelque part
class UserInfo extends User {
  final List<IncomeEntry> incomes;
  final List<JobEntry> jobIncomes;
  // Une entrée par catégorie de personne à charge (cf. TenantList.
  // typesPersonneCharge, calquée sur le formulaire de déclaration de
  // revenus) plutôt qu'un simple compteur global.
  final List<DependentEntry> dependents;

  String familySituation;
  // Adresse actuelle du locataire pour le dossier de location : propre au
  // dossier (comme dependent/familySituation), pas au compte de base (User
  // n'a pas d'adresse - celle-ci n'a rien à voir avec un lot/résidence).
  // phone en revanche est un champ de compte (super.phone) - modifiable
  // depuis "Modifier mes informations", pas propre au dossier locataire.
  Address address;
  // Renseigné seulement si familySituation l'implique (marié, pacsé,
  // concubinage) - cf. MySituationPersonnelle.
  ConjointInfo conjoint;

  UserInfo({
    this.incomes = const [],
    this.jobIncomes = const [],
    this.dependents = const [],
    this.familySituation = "",
    required super.nationality,
    super.phone,
    Address? address,
    ConjointInfo? conjoint,
    required super.email,
    required super.privacyPolicy,
    required super.name,
    required super.surname,
    required super.birthday,
    required super.sex,
    required super.placeOfborn,
    required super.uid,
    super.pseudo,
    super.private = true,
    required super.isApproved,
    super.createdDate,
    super.bio,
    super.profilPic,
  })  : address = address ?? Address(),
        conjoint = conjoint ?? ConjointInfo();

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    final List incomesFromMap = map['revenus'] ?? [];
    final List jobIncomesFromMap = map['activities'] ?? [];
    final userGroup = (map['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final profilGroup = (map['profil'] as Map?)?.cast<String, dynamic>() ?? {};

    return UserInfo(
      email: map['email'] ?? "",
      name: userGroup['name'] ?? "",
      surname: userGroup['surname'] ?? "",
      sex: userGroup['sex'] ?? "",
      nationality: userGroup['nationality'] ?? "",
      placeOfborn: userGroup['placeOfborn'] ?? "",
      pseudo: profilGroup['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      isApproved: map['isApproved'] ?? false,
      bio: profilGroup['bio'],
      private: profilGroup['private'] ?? false,
      createdDate: map['createdDate'] as Timestamp?,
      profilPic: profilGroup['profilPic'] ?? "",
      birthday: userGroup['birthday'] as Timestamp,
      dependents: ((map['dependents'] as List<dynamic>?) ?? [])
          .map((entry) => DependentEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
      familySituation: map['familySituation'] ?? "",
      phone: profilGroup['phone'] ?? "",
      address: Address.fromJson(map['address'] as Map<String, dynamic>?),
      conjoint: ConjointInfo.fromJson(map['conjoint'] as Map<String, dynamic>?),
      privacyPolicy: map['privacyPolicy'] ?? false,
      jobIncomes: jobIncomesFromMap
          .map((entry) => JobEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
      incomes: incomesFromMap
          .map((entry) => IncomeEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'dependents': dependents.map((entry) => entry.toMap()).toList(),
      'familySituation': familySituation,
      'address': address.toJson(),
      'conjoint': conjoint.toJson(),
      // Clés alignées sur fromMap() ci-dessus et sur le format réellement
      // écrit en Firestore (databases_user_services.dart, updateUserInfo) :
      // "revenus"/"activities", pas "incomes"/"jobIncomes".
      'revenus': incomes.map((entry) => entry.toMap()).toList(),
      'activities': jobIncomes.map((entry) => entry.toMap()).toList(),
    };
  }

  Map<String, dynamic> toMapForExport() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'pseudo': pseudo,
      'uid': uid,
      'profilPic': profilPic,
      'isApproved': isApproved,
      'createdDate': createdDate != null
          ? DateFormat('dd/MM/yyyy').format(createdDate!.toDate())
          : null,
      'bio': bio,
      'private': private,
      'birthday': DateFormat('dd/MM/yyyy').format(birthday.toDate()),
      'dependents': dependents.map((entry) => entry.toMap()).toList(),
      'familySituation': familySituation,
      'nationality': nationality,
      'phone': phone,
      'address': address.toJson(),
      'conjoint': conjoint.toJson(),
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
      'jobIncomes': jobIncomes.map((entry) => entry.toMap()).toList(),
    };
  }

  UserInfo copyWith({
    String? email,
    List<IncomeEntry>? incomes,
    List<JobEntry>? jobIncomes,
    List<DependentEntry>? dependents,
    String? familySituation,
    String? phone,
    Address? address,
    ConjointInfo? conjoint,
    String? typeContract,
    Timestamp? entryJobDate,
    String? profession,
    bool? privacyPolicy,
    String? name,
    String? surname,
    Timestamp? birthday,
    String? sex,
    String? nationality,
    String? placeOfborn,
    String? uid,
    String? pseudo,
    bool? private,
    bool? isApproved,
    Timestamp? createdDate,
    String? bio,
    String? profilPic,
  }) {
    return UserInfo(
      email: email ?? this.email,
      incomes: incomes ?? this.incomes,
      jobIncomes: jobIncomes ?? this.jobIncomes,
      dependents: dependents ?? this.dependents,
      familySituation: familySituation ?? this.familySituation,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      conjoint: conjoint ?? this.conjoint,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      birthday: birthday ?? this.birthday,
      sex: sex ?? this.sex,
      nationality: nationality ?? this.nationality,
      placeOfborn: placeOfborn ?? this.placeOfborn,
      uid: uid ?? this.uid,
      pseudo: pseudo ?? this.pseudo,
      private: private ?? this.private,
      isApproved: isApproved ?? this.isApproved,
      createdDate: createdDate ?? this.createdDate,
      bio: bio ?? this.bio,
      profilPic: profilPic ?? this.profilPic ?? '',
    );
  }
}
