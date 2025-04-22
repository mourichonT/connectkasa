import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String email;
  String _profilPic = "";
  String name;
  String surname;
  Timestamp birthday;
  String sex;
  String nationality;
  String placeOfborn;
  String? pseudo;
  String uid;
  String? profession;
  String? bio;
  Timestamp? createdDate;
  bool approved;
  bool private;
  bool privacyPolicy;

  User({
    required this.privacyPolicy,
    required this.email,
    String profilPic = "",
    required this.name,
    required this.surname,
    required this.birthday,
    required this.sex,
    required this.nationality,
    required this.placeOfborn,
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
      privacyPolicy: map['privacyPolicy'] ?? false,
      email: map['email'] ?? "",
      profilPic: map['profilPic'] ?? "",
      approved: map['approved'] ?? false,
      createdDate: map['createdDate'] != null
          ? map['createdDate'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(0),
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      birthday: map['birthday'] != null
          ? map['birthday'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(0),
      sex: map['sex'] ?? "",
      nationality: map['nationality'] ?? "",
      placeOfborn: map['placeOfborn'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      profession: map['profession'] ?? "",
      bio: map['bio'] ?? "",
      private: map['private'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'privacyPolicy': privacyPolicy,
      'profilPic': profilPic,
      'approved': approved,
      'createdDate': createdDate,
      'name': name,
      'surname': surname,
      'birthday': birthday,
      'sex': sex,
      'nationality': nationality,
      'placeOfborn': placeOfborn,
      'pseudo': pseudo,
      'uid': uid,
      'profession': profession,
      'bio': bio,
      'private': private,
    };
  }
}
