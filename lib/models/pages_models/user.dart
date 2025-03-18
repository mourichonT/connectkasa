import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String email;
  String _profilPic = "";
  String name;
  String surname;
  Timestamp birthday;
  String? pseudo;
  String uid;
  String? profession;
  String? bio;
  Timestamp? createdDate;
  bool approved;
  bool private;

  User({
    required this.email,
    String profilPic = "",
    required this.name,
    required this.surname,
    required this.birthday,
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

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? "",
      profilPic: map['profilPic'] ?? "",
      approved: map['approved'] ?? false,
      createdDate: map['createdDate'] ?? "",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      birthday: map['birthday'] as Timestamp,
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      profession: map['profession'] ??
          "", // Pas besoin de fournir une valeur par défaut, car c'est déjà un champ optionnel
      bio: map['bio'] ??
          "", // Pas besoin de fournir une valeur par défaut, car c'est déjà un champ optionnel
      private: map['private'] ??
          false, // Si 'private' est null, utilisez false par défaut
      // Ajout du solde lors de la création d'une instance depuis une Map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profilPic': profilPic,
      'approved': approved,
      'createdDate': createdDate,
      'name': name,
      'surname': surname,
      'birthday': birthday,
      'pseudo': pseudo,
      'uid': uid,
      'profession': profession,
      'bio': bio,
      'private': private,
    };
  }
}
