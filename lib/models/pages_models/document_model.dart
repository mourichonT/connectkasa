import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  String type;
  String? name;
  Timestamp timeStamp;
  String _documentPathRecto = "";
  String? _documentPathVerso = "";
  String? lotId;
  String? residenceId;
  String? extension;
  List<String>? destinataire;

  DocumentModel({
    required this.type,
    this.residenceId,
    required this.timeStamp,
    this.name,
    String documentPathRecto = "",
    String documentPathVerso = "",
    this.lotId,
    this.extension,
    this.destinataire,
  }) {
    _documentPathRecto = documentPathRecto;
    _documentPathVerso = documentPathVerso;
  }

  String get documentPathRecto {
    return _documentPathRecto;
  }

  // set document1(String newUrl) {
  //   if (newUrl != "") {
  //     _documentPathRecto = newUrl;
  //   }
  // }

  String? get documentPathVerso {
    return _documentPathVerso;
  }

  // set document2(String newUrl) {
  //   if (newUrl != "") {
  //     _documentPathVerso = newUrl;
  //   }
  // }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    List<String> destinataireList = [];
    if (json['destinataire'] is List) {
      // Itérer sur la liste et ajouter les éléments convertis en chaînes de caractères
      for (var item in json['destinataire']) {
        if (item is String) {
          destinataireList.add(item);
        }
      }
    }
    return DocumentModel(
        documentPathRecto: json['documentPathRecto'],
        documentPathVerso: json['documentPathVerso'] ?? "",
        name: json['name'],
        type: json['type'],
        timeStamp: json['timeStamp'],
        residenceId: json['residenceId'] ?? "",
        lotId: json['lotId'] ?? "",
        extension: json['extension'] ?? "",
        destinataire: destinataireList ?? []);
  }
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (documentPathVerso != null) 'documentPathVerso': documentPathVerso,
      if (residenceId != null) 'residenceId': residenceId,
      if (lotId != null) 'lotId': lotId,
      if (destinataire != null) 'destinataire': destinataire,
      'type': type,
      'timeStamp': timeStamp,
      'documentPathRecto': documentPathRecto,
      'extension': extension,
    };
  }
}
