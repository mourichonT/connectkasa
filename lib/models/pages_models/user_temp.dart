import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/models/pages_models/user.dart';

class UserTemp extends User {
  // String statutResident;
  String typeLot;
  bool? compagnyBuy;

  UserTemp({
    required super.privacyPolicy,
    required super.email,
    required super.name,
    required super.surname,
    required super.sex,
    required super.nationality,
    required super.placeOfborn,
    super.createdDate,
    super.pseudo,
    super.isInfoCorrect,
    required super.uid,
    required super.isApproved,
    //required this.statutResident,
    required this.typeLot,
    required super.birthday,
    this.compagnyBuy,
  });

  factory UserTemp.fromMap(Map<String, dynamic> map) {
    return UserTemp(
        privacyPolicy: map['privacyPolicy'],
        birthday: map['birthday'] as Timestamp,
        createdDate: map['createdDate'] ?? Timestamp.now(),
        email: map['email'],
        name: map['name'],
        surname: map['surname'],
        sex: map['sex'],
        nationality: map['nationality'],
        placeOfborn: map['placeOfborn'],
        pseudo: map['pseudo'],
        uid: map['uid'],
        isApproved: map['isApproved'] ?? false,
        //statutResident: map['statutResident'],
        typeLot: map['typeLot'],
        compagnyBuy: map['compagnyBuy'] ?? false,
        );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['email'] = email;
    // map['statutResident'] = statutResident;
    map['compagnyBuy'] = compagnyBuy ?? false;
    map['createdDate'] = createdDate ?? Timestamp.now();
    return map;
  }
}
