import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:konodal/models/pages_models/guarantor_info.dart';
// import 'package:konodal/models/pages_models/user_info.dart';

class DemandeLoc {
  final String? id;
  final Timestamp? timestamp;
  final String? tenantId;
  final List<String>? garantId;
  final bool open;
  // Uid du bailleur destinataire (users/{landlordId}/demandes_loc/{id}) :
  // dérivé du chemin Firestore, jamais stocké dans le document lui-même
  // (cf. getSentDemandes, requête collectionGroup côté locataire).
  final String? landlordId;
  // Adresse du lot visé, saisie librement par le locataire dans la modale
  // "Destinataire" (informative uniquement, pas liée à un Address/lot
  // existant) : aide le bailleur qui gère plusieurs biens à identifier le
  // lot concerné par la demande.
  final String? lotAddress;
  // Numéro de lot, optionnel (le locataire ne le connaît pas toujours).
  final String? lotNumero;
  // Le bailleur a explicitement refusé cette demande (bouton "Refuser" de
  // TenantDetail) : le document n'est alors PAS supprimé (contrairement à
  // une demande acceptée, cf. _addTenantToLot) pour que le locataire voie
  // le statut "Refusé" dans "Mes demandes en cours" au lieu de la voir
  // disparaître silencieusement.
  final bool refused;
  // Motif de refus (choisi dans une liste fermée, cf. TenantList.
  // motifsRefusLocation) et date à laquelle le refus a été notifié - le
  // locataire doit pouvoir en prendre connaissance dans "Mes demandes en
  // cours" avant même de retirer sa demande.
  final String? refusalReason;
  final Timestamp? refusedAt;
  // final UserInfo? tenant;
  //final List<GuarantorInfo?>? garant;

  DemandeLoc({
    this.id,
    this.timestamp,
    this.tenantId,
    this.garantId,
    this.open = false,
    this.landlordId,
    this.lotAddress,
    this.lotNumero,
    this.refused = false,
    this.refusalReason,
    this.refusedAt,
  });

  factory DemandeLoc.fromJson(Map<String, dynamic> json,
      {String? id, String? landlordId}) {
    return DemandeLoc(
      id: id,
      timestamp: json['timestamp'] ?? Timestamp.now(),
      tenantId: json['tenantId'] ?? "",
      garantId: (json['garantId'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      open: json['open'] ?? false,
      landlordId: landlordId,
      lotAddress: json['lotAddress'],
      lotNumero: json['lotNumero'],
      refused: json['refused'] ?? false,
      refusalReason: json['refusalReason'],
      refusedAt: json['refusedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'tenantId': tenantId,
      'garantId': garantId,
      'open': open,
      'lotAddress': lotAddress,
      'lotNumero': lotNumero,
      'refused': refused,
      'refusalReason': refusalReason,
      'refusedAt': refusedAt,
      // 'tenant': tenant!.toMap(),
      // 'garant': garant!.map((e) => e!.toMap()).toList(),
    };
  }
}
