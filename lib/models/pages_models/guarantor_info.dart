import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/dependent_entry.dart';
import 'package:konodal/controllers/features/income_entry.dart';
import 'package:konodal/controllers/features/job_entry.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:intl/intl.dart';

class GuarantorInfo {
  final List<IncomeEntry> incomes;
  final List<JobEntry> jobIncomes;
  final String? id;
  // Une entrée par catégorie de personne à charge (cf. TenantList.
  // typesPersonneCharge) plutôt qu'un simple compteur global.
  final List<DependentEntry> dependents;
  String familySituation;
  String phone;
  String email;
  String name;
  String surname;
  Timestamp birthday;
  String sex;
  String nationality;
  String placeOfborn;
  // Lien avec le locataire (cf. TenantList.liensGarantLocataire).
  String relationToTenant;
  // Adresse actuelle du garant : le justificatif de domicile fait partie
  // des pièces qu'un bailleur peut légalement demander à la caution, au
  // même titre qu'au locataire (décret n°2015-1437).
  Address address;

  GuarantorInfo({
    this.id,
    this.incomes = const [],
    this.jobIncomes = const [],
    this.dependents = const [],
    this.familySituation = "",
    this.phone = "",
    this.relationToTenant = "",
    Address? address,
    required this.email,
    required this.name,
    required this.surname,
    required this.birthday,
    required this.sex,
    required this.nationality,
    required this.placeOfborn,
  }) : address = address ?? Address();

  factory GuarantorInfo.fromMap(Map<String, dynamic> map) {
    final List incomesFromMap = map['incomes'] ?? [];
    final List jobIncomesFromMap = map['jobIncomes'] ?? [];

    return GuarantorInfo(
      id: map['id'] ?? "",
      email: map['email'] ?? "",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      birthday: map['birthday'] as Timestamp,
      sex: map['sex'] ?? "",
      nationality: map['nationality'] ?? "",
      placeOfborn: map['placeOfborn'] ?? "",
      dependents: ((map['dependents'] as List<dynamic>?) ?? [])
          .map((entry) => DependentEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
      familySituation: map['familySituation'] ?? "",
      phone: map['phone'] ?? "",
      relationToTenant: map['relationToTenant'] ?? "",
      address: Address.fromJson(map['address'] as Map<String, dynamic>?),
      jobIncomes: jobIncomesFromMap
          .map((entry) => JobEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
      incomes: incomesFromMap
          .map((entry) => IncomeEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'name': name,
      'surname': surname,
      'birthday': birthday,
      'sex': sex,
      'nationality': nationality,
      'placeOfborn': placeOfborn,
      'incomes': incomes.map((e) => e.toMap()).toList(),
      'jobIncomes': jobIncomes.map((e) => e.toMap()).toList(),
      'dependents': dependents.map((entry) => entry.toMap()).toList(),
      'familySituation': familySituation,
      'phone': phone,
      'relationToTenant': relationToTenant,
      'address': address.toJson(),
    };
  }

  Map<String, dynamic> toMapForExport() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'birthday': DateFormat('dd/MM/yyyy').format(birthday.toDate()),
      'sex': sex,
      'nationality': nationality,
      'placeOfborn': placeOfborn,
      'dependents': dependents.map((entry) => entry.toMap()).toList(),
      'familySituation': familySituation,
      'phone': phone,
      'relationToTenant': relationToTenant,
      'address': address.toJson(),
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
      'jobIncomes': jobIncomes.map((entry) => entry.toMap()).toList(),
    };
  }

  GuarantorInfo copyWith({
    String? id,
    String? email,
    List<IncomeEntry>? incomes,
    List<JobEntry>? jobIncomes,
    List<DependentEntry>? dependents,
    String? familySituation,
    String? phone,
    String? relationToTenant,
    Address? address,
    String? name,
    String? surname,
    Timestamp? birthday,
    String? sex,
    String? nationality,
    String? placeOfborn,
  }) {
    return GuarantorInfo(
      id: id ?? this.id,
      email: email ?? this.email,
      incomes: incomes ?? this.incomes,
      jobIncomes: jobIncomes ?? this.jobIncomes,
      dependents: dependents ?? this.dependents,
      familySituation: familySituation ?? this.familySituation,
      phone: phone ?? this.phone,
      relationToTenant: relationToTenant ?? this.relationToTenant,
      address: address ?? this.address,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      birthday: birthday ?? this.birthday,
      sex: sex ?? this.sex,
      nationality: nationality ?? this.nationality,
      placeOfborn: placeOfborn ?? this.placeOfborn,
    );
  }
}
