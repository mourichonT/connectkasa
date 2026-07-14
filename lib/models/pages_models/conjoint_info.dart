import 'package:cloud_firestore/cloud_firestore.dart';

/// Informations sur le conjoint/partenaire du locataire, affichées
/// uniquement quand la situation familiale l'implique (marié, pacsé,
/// concubinage) - cf. MySituationPersonnelle.
class ConjointInfo {
  String name;
  String surname;
  Timestamp? birthday;
  String nationality;

  ConjointInfo({
    this.name = '',
    this.surname = '',
    this.birthday,
    this.nationality = '',
  });

  bool get isEmpty =>
      name.isEmpty && surname.isEmpty && birthday == null && nationality.isEmpty;

  factory ConjointInfo.fromJson(Map<String, dynamic>? json) {
    return ConjointInfo(
      name: json?['name'] ?? '',
      surname: json?['surname'] ?? '',
      birthday: json?['birthday'] as Timestamp?,
      nationality: json?['nationality'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'birthday': birthday,
      'nationality': nationality,
    };
  }
}
