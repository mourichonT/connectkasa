import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/income_entry.dart';
import 'package:connect_kasa/controllers/features/job_entry.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:intl/intl.dart';

// Assure-toi que JobEntry est bien défini quelque part
class UserInfo extends User {
  final List<IncomeEntry> incomes;
  final List<JobEntry> jobIncomes;

  int dependent;
  String familySituation;
  String phone;

  UserInfo({
    this.incomes = const [],
    this.jobIncomes = const [],
    this.dependent = 0,
    this.familySituation = "",
    required super.nationality,
    this.phone = "",
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
    required super.approved,
    super.createdDate,
    super.bio,
    super.profilPic,
  });

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    final List incomesFromMap = map['revenus'] ?? [];
    final List jobIncomesFromMap = map['activities'] ?? [];

    return UserInfo(
      email: map['email'] ?? "",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      sex: map['sex'] ?? "",
      nationality: map['nationality'] ?? "",
      placeOfborn: map['placeOfborn'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      approved: map['approved'] ?? false,
      bio: map['bio'],
      private: map['private'] ?? false,
      createdDate: map['createdDate'] as Timestamp?,
      profilPic: map['profilPic'] ?? "",
      birthday: map['birthday'] as Timestamp,
      dependent: map['dependent'] ?? 0,
      familySituation: map['familySituation'] ?? "",
      phone: map['phone'] ?? "",
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
      'dependent': dependent,
      'familySituation': familySituation,
      'phone': phone,
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
      'approved': approved,
      'createdDate': createdDate != null
          ? DateFormat('dd/MM/yyyy').format(createdDate!.toDate())
          : null,
      'bio': bio,
      'private': private,
      'birthday': birthday != null
          ? DateFormat('dd/MM/yyyy').format(birthday.toDate())
          : null,
      'dependent': dependent,
      'familySituation': familySituation,
      'nationality': nationality,
      'phone': phone,
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
      'jobIncomes': jobIncomes.map((entry) => entry.toMap()).toList(),
    };
  }

  UserInfo copyWith({
    String? email,
    List<IncomeEntry>? incomes,
    List<JobEntry>? jobIncomes,
    int? dependent,
    String? familySituation,
    String? phone,
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
    bool? approved,
    String? bio,
    String? profilPic,
  }) {
    return UserInfo(
      email: email ?? this.email,
      incomes: incomes ?? this.incomes,
      jobIncomes: jobIncomes ?? this.jobIncomes,
      dependent: dependent ?? this.dependent,
      familySituation: familySituation ?? this.familySituation,
      phone: phone ?? this.phone,
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
      approved: approved ?? this.approved,
      createdDate: createdDate ?? this.createdDate,
      bio: bio ?? this.bio,
      profilPic: profilPic ?? this.profilPic ?? '',
    );
  }
}
