import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String id; // Unique ID field
  String amount;
  String fees;
  String uidAcheteur;
  String uidVendeur;
  String statut;
  String postId;
  String residenceId;
  Timestamp validationDate;
  Timestamp? paymentDate;

  TransactionModel({
    required this.id, // Include id in the constructor
    required this.fees,
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
      id: json['id'], // Parse id from JSON
      amount: json['amount'],
      fees: json['fees'],
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
      'id': id, // Include id in the JSON map
      'amount': amount,
      'fees': fees,
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
