import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/former_tenant.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';

class Lot {
  String? id; // ID du document Firestore residences/{id}/lot/{id}, reporté dans ce champ en base à la création
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
  // Lien parent-enfant entre lots d'une même résidence (ex: un parking
  // rattaché à un appartement) - cf. project_lot_parent_child (mémoire) :
  // parentLotId est permanent (idProprietaire du parent toujours recopié
  // vers l'enfant, tant qu'il est défini) ; groupedWithParent est une
  // bascule indépendante (idLocataire recopié seulement si true - locataire
  // indépendant possible sinon). Géré côté serveur par sync_lot_tenants,
  // jamais modifié directement par le client ailleurs que via l'action de
  // liaison/déliaison dédiée.
  String? parentLotId;
  bool groupedWithParent;
  // Un lot ne peut devenir enfant (parentLotId) que si isLinkable est vrai -
  // décidé par un CS member à la création du lot (manage_list_lot.dart),
  // jamais par le propriétaire : empêche qu'un propriétaire lie un
  // appartement entier à un autre pour s'y ajouter sans fournir aucun
  // justificatif. Défaut par type (defaultIsLinkableForType) : faux pour un
  // logement principal (appartement, maison/villa...), vrai pour un lot
  // dépendant (parking, cave...).
  bool isLinkable;
  // Position d'affichage dans la liste "Gestion des Lots" (manage_list_lot.dart),
  // triée par ordre croissant - null pour un lot pas encore ordonné
  // manuellement (relégué en fin de liste, cf. le tri qui l'utilise).
  int? order;
  String residenceId;
  Map<String, dynamic> residenceData;
  Map<String, dynamic> userLotDetails;

  /// Adresse de la résidence (residenceData['address']) : les champs
  /// numero/avenue/street/zipCode/city sont regroupés sous 'address' côté
  /// Firestore (cf. Residence/Address). Retombe sur residenceData lui-même
  /// si 'address' est absent, pour rester compatible avec d'anciens
  /// documents pas encore migrés vers la structure imbriquée.
  Map<String, dynamic> get residenceAddress {
    final nested = residenceData['address'];
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return residenceData;
  }
  // syndicAgency (en réalité une gérance locative pour un lot, cf.
  // modify_prop_info_loc.dart : recherche sur le département
  // "geranceLocative") : cache d'affichage, résolu depuis geranceRef ou
  // saisie custom si non référencée dans gerances. Jamais les deux non-null
  // en base.
  Agency? syndicAgency;
  GeranceRef? geranceRef;

  /// Vrai si une gérance locative est affectée à ce lot, qu'elle soit
  /// référencée dans gerances (pas encore résolue localement) ou custom.
  bool get hasAgency => syndicAgency != null || geranceRef != null;

  /// Valeur par défaut suggérée pour isLinkable selon le type de bien -
  /// utilisée pour pré-remplir le switch dans manage_list_lot.dart,
  /// librement ajustable ensuite par le CS member.
  static bool defaultIsLinkableForType(String typeLot) {
    const mainDwellingTypes = {
      "Appartement",
      "Maison/Villa",
      "Local commercial",
      "Bureau",
      "Terrain nu",
      "Hangar/Entrepôt",
    };
    return !mainDwellingTypes.contains(typeLot);
  }

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
    this.parentLotId,
    this.groupedWithParent = false,
    this.isLinkable = false,
    this.order,
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
      // idLocataireOld est encodé par toJson() ci-dessous en JSON pur
      // (leftAt en millisecondsSinceEpoch, pas un Timestamp Firestore) :
      // fromJson() lit donc ce format-là, pas celui de fromMap() (lecture
      // directe Firestore, Timestamp natif).
      idLocataireOld:
          json["idLocataireOld"] != null && json["idLocataireOld"] is List
              ? (json["idLocataireOld"] as List)
                  .map((e) => FormerTenant(
                        uid: e['uid'] ?? '',
                        leftAt: Timestamp.fromMillisecondsSinceEpoch(
                            e['leftAt'] ?? 0),
                      ))
                  .toList()
              : [],
      parentLotId: json["parentLotId"],
      groupedWithParent: json["groupedWithParent"] ?? false,
      isLinkable: json["isLinkable"] ?? false,
      order: json["order"] is int ? json["order"] : null,
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
      // Format JSON pur (leftAt en millisecondsSinceEpoch), pas
      // FormerTenant.toMap() (Timestamp Firestore natif, non encodable par
      // jsonEncode - cause de "JsonUnsupportedObjectError: Instance of
      // 'Timestamp'" dans lot_bottom_sheet.dart avant ce correctif).
      "idLocataireOld": idLocataireOld
          .map((e) => {
                'uid': e.uid,
                'leftAt': e.leftAt.millisecondsSinceEpoch,
              })
          .toList(),
      "parentLotId": parentLotId,
      "groupedWithParent": groupedWithParent,
      "isLinkable": isLinkable,
      "order": order,
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
      parentLotId: map['parentLotId'],
      groupedWithParent: map['groupedWithParent'] ?? false,
      isLinkable: map['isLinkable'] ?? false,
      order: map['order'] is int ? map['order'] : null,
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
      "isLinkable": isLinkable,
      if (order != null) "order": order,
      if (idProprietaire != null) "idProprietaire": idProprietaire,
      if (syndicAgency != null) "syndicAgency": syndicAgency!.toJson(),
      if (geranceRef != null) "geranceRef": geranceRef!.toJson(),
      // On ne met pas userLotDetails ni residenceData ici
    };
  }
}
