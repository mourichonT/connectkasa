import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String amount;
  String uidAcheteur;
  String uidVendeur;
  String statut;
  String postId;
  String residenceId;
  Timestamp validationDate;
  Timestamp? paymentDate;

  TransactionModel({
    required this.amount,
    required this.uidAcheteur,
    required this.uidVendeur,
    required this.statut,
    required this.postId,
    required this.residenceId,
    required this.validationDate,
    this.paymentDate,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      amount: json['amount'],
      uidAcheteur: json['uidAcheteur'],
      uidVendeur: json['uidVendeur'],
      statut: json['statut'],
      postId: json['postId'],
      residenceId: json['residenceId'],
      validationDate: json['validationDate'] ?? 0,
      paymentDate: json['paymentDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'uidAcheteur': uidAcheteur,
      'uidVendeur': uidVendeur,
      'statut': statut,
      'postId': postId,
      'residenceId': residenceId,
      'validationDate': validationDate,
      'paymentDate': paymentDate
    };
  }
}
