import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class UserTemp extends User {
  String statutResident;
  String typeLot;
  bool? compagnyBuy;

  UserTemp(
      {required String name,
      required String surname,
      String? pseudo,
      required String uid,
      required bool approved,
      required this.statutResident,
      required this.typeLot,
      bool? compagnyBuy})
      : super(
          name: name,
          surname: surname,
          pseudo: pseudo,
          uid: uid,
          approved: approved,
        );

  factory UserTemp.fromMap(Map<String, dynamic> map) {
    return UserTemp(
        name: map['name'],
        surname: map['surname'],
        pseudo: map['pseudo'],
        uid: map['uid'],
        approved: map['approved'],
        statutResident: map['statutResident'],
        typeLot: map['typeLot'],
        compagnyBuy: map['compagnyBuy']);
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['statutResident'] = statutResident;
    map['compagnyBuy'] = compagnyBuy;
    return map;
  }
}
