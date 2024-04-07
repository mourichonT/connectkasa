import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  String type;
  String? name;
  Timestamp timeStamp;
  String _documentPathRecto = "";
  String? _documentPathVerso = "";
  String? lotId;
  String residenceId;

  DocumentModel({
    required this.type,
    required this.residenceId,
    required this.timeStamp,
    this.name,
    String documentPathRecto = "",
    String documentPathVerso = "",
    String this.lotId = "",
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
    return DocumentModel(
        documentPathRecto: json['documentPathRecto'],
        documentPathVerso: json['documentPathVerso'] ?? "",
        name: json['name'],
        type: json['type'],
        timeStamp: json['timeStamp'],
        residenceId: json['residenceId'],
        lotId: json['lotId']);
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'documentPathRecto': documentPathRecto,
      'documentPathVerso': documentPathVerso,
      'type': type,
      'timeStamp': timeStamp,
      'residenceId': residenceId,
      'lotId': lotId,
    };
  }
}
