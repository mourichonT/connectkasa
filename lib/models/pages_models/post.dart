class Post {
  String numResidence;
  String numUser;
  String type;
  String date;
  String statu = "";
  String _pathImage = ""; // Utilisation d'une variable privée (_pathImage) pour stocker le chemin de l'image.
  String title;
  String description;
  int like;
  int comment;
  int signalement;

  Post({
    required this.numResidence,
    required this.numUser,
    required this.type,
    required this.date,
    String statu= "",
    String pathImage = "",
    required this.title,
    required this.description,
    this.like = 0,
    this.comment = 0,
    this.signalement = 0,
  }) {
    this._pathImage = pathImage;
  }

  String? get pathImage {
    return _pathImage;
  }

  set image(String newUrl) {
    if (newUrl != "") {
      _pathImage = newUrl;
    }
  }

  String setDate() => "Posté le $date";


  String setLike() {
    return "$like j'aime";
  }

  String setComments() {
    if (comment > 1) {
      return "$comment commentaires";
    } else {
      return "$comment commentaire";
    }
  }

  String setSignalement() {
    if (signalement > 1) {
      return "$signalement signalements";
    } else {
      return "$signalement signalement";
    }
  }

}