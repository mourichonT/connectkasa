import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/income_entry.dart';
import 'package:connect_kasa/controllers/features/job_entry.dart';
import 'package:intl/intl.dart';

class GuarantorInfo {
  final List<IncomeEntry> incomes;
  final List<JobEntry> jobIncomes;
  final String? id;
  int dependent;
  String familySituation;
  String phone;
  String email;
  String name;
  String surname;
  Timestamp birthday;
  String sex;
  String nationality;
  String placeOfborn;

  GuarantorInfo({
    this.id,
    this.incomes = const [],
    this.jobIncomes = const [],
    this.dependent = 0,
    this.familySituation = "",
    this.phone = "",
    required this.email,
    required this.name,
    required this.surname,
    required this.birthday,
    required this.sex,
    required this.nationality,
    required this.placeOfborn,
  });

  factory GuarantorInfo.fromMap(Map<String, dynamic> map, String docId) {
    final List incomesFromMap = map['incomes'] ?? [];
    final List jobIncomesFromMap = map['jobIncomes'] ?? [];

    return GuarantorInfo(
      id: docId,
      email: map['email'] ?? "",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      birthday: map['birthday'] as Timestamp,
      sex: map['sex'] ?? "",
      nationality: map['nationality'] ?? "",
      placeOfborn: map['placeOfborn'] ?? "",
      dependent: map['dependent'] ?? 0,
      familySituation: map['familySituation'] ?? "",
      phone: map['phone'] ?? "",
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
      'email': email,
      'name': name,
      'surname': surname,
      'birthday': birthday,
      'sex': sex,
      'nationality': nationality,
      'placeOfborn': placeOfborn,
      'dependent': dependent,
      'familySituation': familySituation,
      'phone': phone,
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
      'jobIncomes': jobIncomes.map((entry) => entry.toMap()).toList(),
    };
  }

  Map<String, dynamic> toMapForExport() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'birthday': birthday != null
          ? DateFormat('dd/MM/yyyy').format(birthday.toDate())
          : null,
      'sex': sex,
      'nationality': nationality,
      'placeOfborn': placeOfborn,
      'dependent': dependent,
      'familySituation': familySituation,
      'phone': phone,
      'incomes': incomes.map((entry) => entry.toMap()).toList(),
      'jobIncomes': jobIncomes.map((entry) => entry.toMap()).toList(),
    };
  }

  GuarantorInfo copyWith({
    String? id,
    String? email,
    List<IncomeEntry>? incomes,
    List<JobEntry>? jobIncomes,
    int? dependent,
    String? familySituation,
    String? phone,
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
      dependent: dependent ?? this.dependent,
      familySituation: familySituation ?? this.familySituation,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      birthday: birthday ?? this.birthday,
      sex: sex ?? this.sex,
      nationality: nationality ?? this.nationality,
      placeOfborn: placeOfborn ?? this.placeOfborn,
    );
  }
}
