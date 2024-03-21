class User {
  String _profilPic = "";
  String name;
  String surname;
  String pseudo;
  String uid;
  String? profession;
  String? bio;
  bool private;

  User({
    String profilPic = "",
    required this.name,
    required this.surname,
    required this.uid,
    this.profession,
    required this.pseudo,
    this.private = true,
    this.bio,
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
      profilPic: map['profilPic'] ?? "",
      name: map['name'] ?? "",
      surname: map['surname'] ?? "",
      pseudo: map['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      profession: map[
          'profession'], // Pas besoin de fournir une valeur par défaut, car c'est déjà un champ optionnel
      bio: map[
          'bio'], // Pas besoin de fournir une valeur par défaut, car c'est déjà un champ optionnel
      private: map['private'] ??
          true, // Si 'private' est null, utilisez false par défaut
    );
  }
}
