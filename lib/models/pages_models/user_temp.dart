import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class UserTemp extends User {
  // String statutResident;
  String typeLot;
  bool? compagnyBuy;

  UserTemp({
    required super.email,
    required super.name,
    required super.surname,
    super.createdDate,
    super.pseudo,
    required super.uid,
    required super.approved,
    //required this.statutResident,
    required this.typeLot,
    required super.birthday,
    // bool? compagnyBuy
  });

  factory UserTemp.fromMap(Map<String, dynamic> map) {
    return UserTemp(
        birthday: map['birthday'] as Timestamp,
        createdDate: map['createdDate'] ?? Timestamp.now(),
        email: map['email'],
        name: map['name'],
        surname: map['surname'],
        pseudo: map['pseudo'],
        uid: map['uid'],
        approved: map['approved'],
        //statutResident: map['statutResident'],
        typeLot: map['typeLot']
        //compagnyBuy: map['compagnyBuy']??false
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
