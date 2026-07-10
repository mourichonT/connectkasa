import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/former_tenant.dart';
import 'package:connect_kasa/models/pages_models/gerance_ref.dart';

class Lot {
  String? id; // ID du document Firestore Residence/{id}/lot/{id}, reporté dans ce champ en base à la création
  String refLot;
  String? batiment;
  String? lot;
  String typeLot;
  String? refGerance;
  String type;
  List<String>? idProprietaire;
  List<String>? idLocataire;
  // Historique des locataires révoqués de ce lot (onglet "Historique" de
  // ManagementTenant) - jamais null, [] par défaut.
  List<FormerTenant> idLocataireOld;
  String residenceId;
  Map<String, dynamic> residenceData;
  Map<String, dynamic> userLotDetails;
  // syndicAgency (en réalité une gérance locative pour un lot, cf.
  // modify_prop_info_loc.dart : recherche sur le département
  // "geranceLocative") : cache d'affichage, résolu depuis geranceRef ou
  // saisie custom si non référencée dans Gerance. Jamais les deux non-null
  // en base.
  Agency? syndicAgency;
  GeranceRef? geranceRef;

  /// Vrai si une gérance locative est affectée à ce lot, qu'elle soit
  /// référencée dans Gerance (pas encore résolue localement) ou custom.
  bool get hasAgency => syndicAgency != null || geranceRef != null;

  Lot({
    String nameProp = "",
    String nameLoc = "",
    this.id,
    required this.refLot,
    this.batiment,
    this.lot,
    required this.typeLot,
    this.refGerance,
    required this.type,
    required this.idProprietaire,
    this.idLocataire,
    this.idLocataireOld = const [],
    required this.residenceId,
    required this.residenceData,
    required this.userLotDetails,
    this.syndicAgency,
    this.geranceRef,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json["id"],
      refLot: json["refLot"] ?? "",
      batiment: json["batiment"],
      lot: json["lot"],
      typeLot: json["typeLot"] ?? "",
      refGerance: json["refGerance"],
      type: json["type"] ?? "",
      idProprietaire:
          json["idProprietaire"] != null && json["idProprietaire"] is List
              ? List<String>.from(json["idProprietaire"])
              : [],
      // [] par défaut, jamais null (aligné sur fromMap ci-dessous) : de
      // nombreux écrans font idLocataire! en supposant que ce n'est jamais
      // null.
      idLocataire: json["idLocataire"] != null && json["idLocataire"] is List
          ? List<String>.from(json["idLocataire"])
          : [],
      idLocataireOld:
          json["idLocataireOld"] != null && json["idLocataireOld"] is List
              ? (json["idLocataireOld"] as List)
                  .map((e) => FormerTenant.fromMap(Map<String, dynamic>.from(e)))
                  .toList()
              : [],
      residenceId: json["residenceId"] ?? "",
      residenceData: json["residenceData"] != null
          ? Map<String, dynamic>.from(json["residenceData"])
          : {},
      userLotDetails: json["userLotDetails"] != null
          ? Map<String, dynamic>.from(json["userLotDetails"])
          : {},
      syndicAgency: json["syndicAgency"] != null
          ? Agency.fromJson(json["syndicAgency"])
          : null,
      geranceRef: json["geranceRef"] != null
          ? GeranceRef.fromJson(json["geranceRef"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "refLot": refLot,
      "batiment": batiment,
      "lot": lot,
      "typeLot": typeLot,
      "refGerance": refGerance,
      "type": type,
      "idProprietaire": idProprietaire,
      "idLocataire": idLocataire,
      "idLocataireOld": idLocataireOld.map((e) => e.toMap()).toList(),
      "residenceId": residenceId,
      "residenceData": residenceData,
      'userLotDetails': userLotDetails,
      'syndicAgency': syndicAgency?.toJson(),
      'geranceRef': geranceRef?.toJson(),
    };
  }

  void setNumLoc(String newValue) {
    _addNumLoc(newValue);
  }

  void _addNumLoc(String newValue) {
    idLocataire?.add(newValue);
  }

  void setNumProp(String newValue) {
    _addNumProp(newValue);
  }

  void _addNumProp(String newValue) {
    idProprietaire?.add(newValue);
  }

  factory Lot.fromMap(Map<String, dynamic> map) {
    return Lot(
      id: map['id'],
      refLot: map['refLot'] ?? "",
      batiment: map['batiment'],
      lot: map['lot'],
      typeLot: map['typeLot'] ?? "",
      refGerance: map["refGerance"],
      type: map['type'] ?? "",
      // Vérification de type défensive (alignée sur fromJson ci-dessus) :
      // évite un crash si le champ existe mais n'est pas une liste.
      idProprietaire: map['idProprietaire'] is List
          ? List<String>.from(map['idProprietaire'])
          : [],
      idLocataire:
          map['idLocataire'] is List ? List<String>.from(map['idLocataire']) : [],
      idLocataireOld: map['idLocataireOld'] is List
          ? (map['idLocataireOld'] as List)
              .map((e) => FormerTenant.fromMap(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      residenceId: map["residenceId"] ?? "",
      residenceData: map["residenceData"] != null
          ? Map<String, dynamic>.from(map["residenceData"])
          : {},
      userLotDetails: map["userLotDetails"] != null
          ? Map<String, dynamic>.from(map["userLotDetails"])
          : {},
      syndicAgency: map['syndicAgency'] != null
          ? Agency.fromJson(map['syndicAgency'])
          : null,
      geranceRef: map['geranceRef'] != null
          ? GeranceRef.fromJson(map['geranceRef'])
          : null,
    );
  }

  Map<String, dynamic> toJsonForDb() {
    return {
      if (id != null) "id": id,
      if (refLot.isNotEmpty) "refLot": refLot,
      if (refGerance != null) "refGerance": refGerance,
      if (batiment != null) "batiment": batiment,
      if (lot != null) "lot": lot,
      if (typeLot.isNotEmpty) "typeLot": typeLot,
      if (type.isNotEmpty) "type": type,
      if (idProprietaire != null) "idProprietaire": idProprietaire,
      if (syndicAgency != null) "syndicAgency": syndicAgency!.toJson(),
      if (geranceRef != null) "geranceRef": geranceRef!.toJson(),
      // On ne met pas userLotDetails ni residenceData ici
    };
  }
}
