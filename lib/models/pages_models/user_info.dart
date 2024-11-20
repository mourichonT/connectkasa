import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class UserInfo extends User {
  Timestamp birthday; // Conversion depuis Timestamp dans Firestore
  bool additionalRevenu;
  String amountFamilyAllowance;
  String amountAdditionalRevenu;
  String amountHousingAllowance;
  int dependent;
  bool familyAllowance;
  String familySituation;
  bool housingAllowance;
  String nationality;
  String phone;
  String salary;
  String typeContract;

  UserInfo({
    required this.birthday,
    required this.additionalRevenu,
    this.amountFamilyAllowance = "",
    this.amountAdditionalRevenu = "",
    this.amountHousingAllowance = "",
    this.dependent = 0,
    this.familyAllowance = false,
    this.familySituation = "",
    this.housingAllowance = true,
    this.nationality = "",
    this.phone = "",
    this.salary = "",
    this.typeContract = "",
    required super.name,
    required super.surname,
    required super.uid,
    super.profession,
    super.pseudo,
    super.private = true,
    required super.approved,
    super.createdDate,
    super.bio,
    String solde = "0",
    String profilPic = "",
  }) : super(
          profilPic: profilPic,
          solde: solde,
        );

  /// Méthode pour créer une instance depuis une Map
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      approved: map['approved'] ?? false,
      profession: map['profession'],
      bio: map['bio'],
      private: map['private'] ?? false,
      createdDate: map['createdDate'] as Timestamp?,
      profilPic: map['profilPic'] ?? "",
      solde: map['solde'] ?? "0",
      birthday: map['birthday'] as Timestamp, // Conversion du Timestamp en DateTime
      additionalRevenu: map['additionalRevenu'] ?? false,
      amountFamilyAllowance: map['amountFamilyAllowance'] ?? "",
      amountAdditionalRevenu: map['amountAdditionalRevenu'] ?? "",
      amountHousingAllowance: map['amountHousingAllowance'] ?? "",
      dependent: map['dependent'] ?? 0,
      familyAllowance: map['familyAllowance'] ?? false,
      familySituation: map['familySituation'] ?? "",
      housingAllowance: map['housingAllowance'] ?? true,
      nationality: map['nationality'] ?? "",
      phone: map['phone'] ?? "",
      salary: map['salary'] ?? "",
      typeContract: map['typeContract'] ?? "",
    );
  }

  /// Méthode pour convertir une instance en Map
  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'birthday': birthday, // Conversion de DateTime en Timestamp
      'additionalRevenu': additionalRevenu,
      'amountFamilyAllowance': amountFamilyAllowance,
      'amountAdditionalRevenu': amountAdditionalRevenu,
      'amountHousingAllowance': amountHousingAllowance,
      'dependent': dependent,
      'familyAllowance': familyAllowance,
      'familySituation': familySituation,
      'housingAllowance': housingAllowance,
      'nationality': nationality,
      'phone': phone,
      'salary': salary,
      'typeContract': typeContract,
    };
  }
}
