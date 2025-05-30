import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/enum/income_entry.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:intl/intl.dart';

class UserInfo extends User {
  final List<IncomeEntry> incomes;

  int dependent;
  String familySituation;
  String phone;
  String typeContract;
  Timestamp? entryJobDate;
  String? profession;

  UserInfo({
    super.email = "",
    this.incomes = const [],
    this.dependent = 0,
    this.familySituation = "",
    required super.nationality,
    this.phone = "",
    this.typeContract = "",
    this.entryJobDate,
    required super.privacyPolicy,
    required super.name,
    required super.surname,
    required super.birthday,
    required super.sex,
    required super.placeOfborn,
    required super.uid,
    this.profession,
    super.pseudo,
    super.private = true,
    required super.approved,
    super.createdDate,
    super.bio,
    super.profilPic,
  });

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    final List incomesFromMap = map['revenus'] ?? [];

    return UserInfo(
      privacyPolicy: map['privacyPolicy'] ?? false,
      email: map['email'] ?? "N/C",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      sex: map['sex'] ?? "",
      nationality: map['nationality'] ?? "",
      placeOfborn: map['placeOfborn'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      approved: map['approved'] ?? false,
      profession: map['profession'] ?? "",
      bio: map['bio'],
      private: map['private'] ?? false,
      createdDate: map['createdDate'] as Timestamp?,
      profilPic: map['profilPic'] ?? "",
      birthday: map['birthday'] as Timestamp,
      dependent: map['dependent'] ?? 0,
      familySituation: map['familySituation'] ?? "",
      phone: map['phone'] ?? "",
      typeContract: map['typeContract'] ?? "",
      entryJobDate:
          map['entryJobDate'] != null ? map['entryJobDate'] as Timestamp : null,
      incomes: incomesFromMap
          .map((entry) => IncomeEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'email': email,
      'birthday': birthday,
      'dependent': dependent,
      'familySituation': familySituation,
      'nationality': nationality,
      'phone': phone,
      'typeContract': typeContract,
      'entryJobDate': entryJobDate,
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
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
      'profession': profession,
      'bio': bio,
      'private': private,
      'birthday': birthday != null
          ? DateFormat('dd/MM/yyyy').format(birthday.toDate())
          : null,
      'dependent': dependent,
      'familySituation': familySituation,
      'nationality': nationality,
      'phone': phone,
      'typeContract': typeContract,
      'entryJobDate': entryJobDate != null
          ? DateFormat('dd/MM/yyyy').format(entryJobDate!.toDate())
          : null,
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
    };
  }

  UserInfo copyWith({
    String? email,
    List<IncomeEntry>? incomes,
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
    Timestamp? createdDate,
    String? bio,
    String? profilPic,
  }) {
    return UserInfo(
      email: email ?? this.email,
      incomes: incomes ?? this.incomes,
      dependent: dependent ?? this.dependent,
      familySituation: familySituation ?? this.familySituation,
      phone: phone ?? this.phone,
      typeContract: typeContract ?? this.typeContract,
      entryJobDate: entryJobDate ?? this.entryJobDate,
      profession: profession ?? this.profession,
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
      profilPic: profilPic!,
    );
  }
}
