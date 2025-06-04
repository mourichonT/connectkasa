import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class JobEntry {
  Timestamp? entryJobDate;
  final String profession;
  final String typeContract;

  JobEntry({
    required this.typeContract,
    this.entryJobDate,
    required this.profession,
  });

  factory JobEntry.fromMap(Map<String, dynamic> map) {
    return JobEntry(
      entryJobDate: map['entryJobDate'],
      profession: map['profession'] ?? '',
      typeContract: map['typeContract'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'typeContract': typeContract,
      if (entryJobDate != null) 'entryJobDate': entryJobDate,
      'profession': profession,
    };
  }

  /// Méthode statique pour extraire la liste des revenus depuis une Map
}
