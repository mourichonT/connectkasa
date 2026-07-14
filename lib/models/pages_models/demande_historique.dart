import 'package:cloud_firestore/cloud_firestore.dart';

/// Copie figée d'une demande refusée (users/{landlordId}/demandes_historique/
/// {demandeId}), écrite au moment du refus - persiste même si le locataire
/// retire ensuite sa demande (qui ne supprime que demandes_loc, jamais cette
/// copie), pour que l'onglet "Historique" de ManagementTenant garde une
/// trace : adresse du lot voulu, date de soumission, date de refus, motif.
class DemandeHistorique {
  final String? id;
  final String tenantId;
  final String tenantName;
  final String tenantSurname;
  final String? lotAddress;
  final String? lotNumero;
  final Timestamp? submittedAt;
  final Timestamp? refusedAt;
  final String refusalReason;

  DemandeHistorique({
    this.id,
    required this.tenantId,
    required this.tenantName,
    required this.tenantSurname,
    this.lotAddress,
    this.lotNumero,
    this.submittedAt,
    this.refusedAt,
    required this.refusalReason,
  });

  factory DemandeHistorique.fromJson(Map<String, dynamic> json, {String? id}) {
    return DemandeHistorique(
      id: id,
      tenantId: json['tenantId'] ?? '',
      tenantName: json['tenantName'] ?? '',
      tenantSurname: json['tenantSurname'] ?? '',
      lotAddress: json['lotAddress'],
      lotNumero: json['lotNumero'],
      submittedAt: json['submittedAt'],
      refusedAt: json['refusedAt'],
      refusalReason: json['refusalReason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantSurname': tenantSurname,
      'lotAddress': lotAddress,
      'lotNumero': lotNumero,
      'submittedAt': submittedAt,
      'refusedAt': refusedAt,
      'refusalReason': refusalReason,
    };
  }
}
