class User {
  String _profilPic = "";
  String name;
  String surname;
  String numUser;

  User({
    String profilPic = "",
    required this.name,
    required this.surname,
    required this.numUser,
  }) {
    this._profilPic = profilPic;
  }

  String? get profilPic {
    return _profilPic;
  }

  set imageProfil(String newUrl) {
    if (newUrl != "") {
      _profilPic = newUrl;
    }
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      profilPic: map['profilPic'] ??
          "", // Si 'profilPic' est null, utilisez une chaîne vide par défaut
      name: map['name'] ??
          "", // Si 'name' est null, utilisez une chaîne vide par défaut
      surname: map['surname'] ??
          "", // Si 'surname' est null, utilisez une chaîne vide par défaut
      numUser: map['numUser'] ??
          "", // Si 'numUser' est null, utilisez une chaîne vide par défaut
    );
  }
}
