class User {

  String login;
  String password;
  String _profilPic = "";
  String name;
  String surname;
  String numUser;


  User({
      required this.login,
      required this.password,
      String profilPic="",
      required this.name,
      required this.surname,
      required this.numUser,
  });

  String? get pathImage {
    return _profilPic;
  }

  set imageProfil(String newUrl) {
    if (newUrl != "") {
      _profilPic = newUrl;
    }
  }

}

