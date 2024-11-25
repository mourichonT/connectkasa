import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:intl/intl.dart';

class UserInfo extends User {
  String email;
  Timestamp birthday; // Conversion depuis Timestamp dans Firestore
  String amountFamilyAllowance;
  String amountAdditionalRevenu;
  String amountHousingAllowance;
  int dependent;
  String familySituation;
  String nationality;
  String phone;
  String salary;
  String typeContract;
  Timestamp? entryJobDate;

  UserInfo({
    this.email="",
    required this.birthday,
    this.amountFamilyAllowance = "",
    this.amountAdditionalRevenu = "",
    this.amountHousingAllowance = "",
    this.dependent = 0,
    this.familySituation = "",
    this.nationality = "",
    this.phone = "",
    this.salary = "",
    this.typeContract = "",
    this.entryJobDate,
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
    super.profilPic,
  }) : super(

        );

  /// Méthode pour créer une instance depuis une Map
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      email: map['email']??"N/C",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      approved: map['approved'] ?? false,
      profession: map['profession']??"",
      bio: map['bio'],
      private: map['private'] ?? false,
      createdDate: map['createdDate'] as Timestamp?,
      profilPic: map['profilPic'] ?? "",
      solde: map['solde'] ?? "0",
      birthday: map['birthday'] as Timestamp, // Conversion du Timestamp en DateTime
      amountFamilyAllowance: map['amountFamilyAllowance'] ?? "",
      amountAdditionalRevenu: map['amountAdditionalRevenu'] ?? "",
      amountHousingAllowance: map['amountHousingAllowance'] ?? "",
      dependent: map['dependent'] ?? 0,
      familySituation: map['familySituation'] ?? "",
      nationality: map['nationality'] ?? "",
      phone: map['phone'] ?? "",
      salary: map['salary'] ?? "",
      typeContract: map['typeContract'] ?? "",
      entryJobDate: map['entryJobDate']??"",
    );
  }

Map<String, dynamic> toMapForExport() {
  return {
    'email':email,
    'name': name,
    'surname': surname,
    'pseudo': pseudo,
    'uid': uid,
    'profilPic': profilPic,
    'approved': approved,
    'createdDate': createdDate != null ? DateFormat('dd/MM/yyyy').format(createdDate!.toDate()) : null,
    'profession': profession,
    'bio': bio,
    'private': private,
    'solde': solde,
    'birthday': birthday != null ? DateFormat('dd/MM/yyyy').format(birthday.toDate()) : null,
    'amountFamilyAllowance': amountFamilyAllowance,
    'amountAdditionalRevenu': amountAdditionalRevenu,
    'amountHousingAllowance': amountHousingAllowance,
    'dependent': dependent,
    'familySituation': familySituation,
    'nationality': nationality,
    'phone': phone,
    'salary': salary,
    'typeContract': typeContract,
    'entryJobDate': entryJobDate != null ? DateFormat('dd/MM/yyyy').format(entryJobDate!.toDate()) : null,
  };
}
  /// Méthode pour convertir une instance en Map
  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'email': email,
      'birthday': birthday, // Conversion de DateTime en Timestamp
      'amountFamilyAllowance': amountFamilyAllowance,
      'amountAdditionalRevenu': amountAdditionalRevenu,
      'amountHousingAllowance': amountHousingAllowance,
      'dependent': dependent,
      'familySituation': familySituation,
      'nationality': nationality,
      'phone': phone,
      'salary': salary,
      'typeContract': typeContract,
      'entryJobDate' : entryJobDate
    };
  }



}
