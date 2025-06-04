class JustifDocument {
  String docType;
  String? fileUrl;
  bool isUploaded;

  JustifDocument(
      {required this.docType, this.fileUrl, this.isUploaded = false});

  // Convertir depuis une Map (utile pour Firestore ou le décodage JSON)
  factory JustifDocument.fromMap(Map<String, dynamic> map) {
    return JustifDocument(
      docType: map['docType'] ?? '',
      fileUrl: map['fileUrl'],
    );
  }

  // Convertir vers une Map (utile pour Firestore ou l'encodage JSON)
  Map<String, dynamic> toMap() {
    return {
      'docType': docType,
      'fileUrl': fileUrl,
    };
  }

  // Pour le debug
  @override
  String toString() {
    return 'JustifDocument(docType: $docType, fileUrl: $fileUrl)';
  }
}
