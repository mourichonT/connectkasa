import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class UserTemp extends User {
 // String statutResident;
  String typeLot;
  bool? compagnyBuy;

  UserTemp(
      {
      required String email,  
      required String name,
      required String surname,
      Timestamp? createdDate,
      String? pseudo,
      required String uid,
      required bool approved,
      //required this.statutResident,
      required this.typeLot,
     // bool? compagnyBuy
     })
      : super(
          email: email,
          name: name,
          surname: surname,
          pseudo: pseudo,
          uid: uid,
          approved: approved,
          createdDate: createdDate
        );

  factory UserTemp.fromMap(Map<String, dynamic> map) {
    return UserTemp(
        createdDate: map['createdDate']?? Timestamp.now(),
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
    map['compagnyBuy'] = compagnyBuy??false;
    map['createdDate'] = createdDate ?? Timestamp.now();
    return map;
  }
}
