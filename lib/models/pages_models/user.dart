import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String _profilPic = "";
  String name;
  String surname;
  String? pseudo;
  String uid;
  String? profession;
  String? bio;
  Timestamp? createdDate;
  bool approved;
  bool private;
  String _solde = "0"; // Nouvel attribut pour le solde

  User({
    String profilPic = "",
    required this.name,
    required this.surname,
    required this.uid,
    this.profession,
    this.pseudo,
    this.private = true,
    required this.approved,
    this.createdDate,
    this.bio,
    String solde = "0",
  }) {
    _profilPic = profilPic;
    _solde = solde;
  }

  // Méthode pour obtenir le solde
  String get solde => _solde;

  // Méthode pour définir le solde
  set solde(String newSolde) {
    if (newSolde != '0') {
      _solde = newSolde;
    }
  }

  String? get profilPic {
    return _profilPic;
  }

  set imageProfil(String newUrl) {
    if (newUrl != "") {
      _profilPic = newUrl;
    }
  }

  set setPseudo(String newValue) {
    pseudo = newValue;
  }

  set setPrivate(bool newValue) {
    private = newValue;
  }

  String setSolde(solde) {
    if (solde == 0) {
      return "0 Kasa";
    } else if (solde == "1") {
      return "$solde Kasa";
    } else {
      return "$solde Kasas";
    }
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      profilPic: map['profilPic'] ?? "",
      approved: map['approved'] ?? false,
      createdDate: map['createdDate'] ?? "",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      profession: map[
          'profession'], // Pas besoin de fournir une valeur par défaut, car c'est déjà un champ optionnel
      bio: map[
          'bio'], // Pas besoin de fournir une valeur par défaut, car c'est déjà un champ optionnel
      private: map['private'] ??
          false, // Si 'private' est null, utilisez false par défaut
      solde: map['solde'] ??
          "0", // Ajout du solde lors de la création d'une instance depuis une Map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profilPic': profilPic,
      'approved': approved,
      'createdDate': createdDate,
      'name': name,
      'surname': surname,
      'pseudo': pseudo,
      'uid': uid,
      'profession': profession,
      'bio': bio,
      'private': private,
      'solde': _solde, // Ajout du solde lors de la conversion en Map
    };
  }
}
