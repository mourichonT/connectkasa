import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class Post {
  String refResidence;
  String user;
  String type;
  String _subtype = "";
  Timestamp timeStamp;
  String _statu = "";
  String _pathImage =
      ""; // Utilisation d'une variable privée (_pathImage) pour stocker le chemin de l'image.
  String title;
  String description;
  int like;
  int comment;
  int signalement;

  Post({
    required this.refResidence,
    required this.user,
    required this.type,
    String subtype = "",
    required this.timeStamp,
    String statu = "",
    String pathImage = "",
    required this.title,
    required this.description,
    this.like = 0,
    this.comment = 0,
    this.signalement = 0,
  }) {
    this._pathImage = pathImage;
    this._statu = statu;
    this._subtype = subtype;
  }

  String? get pathImage {
    return _pathImage;
  }

  set image(String newUrl) {
    if (newUrl != "") {
      _pathImage = newUrl;
    }
  }

  String? get subtype {
    return _subtype;
  }

  String? get statu {
    return _statu;
  }

  set newStatu(String? newStatu) {
    if (newStatu != "") {
      _statu = newStatu!;
    }
  }

  String setDate() => "Posté le $timeStamp";

  String setLike() {
    if (like > 1) {
      return "$like Likes";
    } else {
      return "$like Like";
    }
  }

  String setComments() {
    if (comment > 1) {
      return "$comment Commentaires";
    } else {
      return "$comment Commentaire";
    }
  }

  String setSignalement() {
    if (signalement > 1) {
      return "$signalement Signalements";
    } else {
      return "$signalement Signalement";
    }
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
        description: map['description'] ?? "",
        subtype: map['subtype'] ?? "",
        pathImage: map['pathImage'] ?? "",
        refResidence: map['refResidence'] ?? "",
        statu: map['statu'] ?? "",
        timeStamp: map['timeStamp'] ?? 0,
        title: map['title'] ?? "",
        type: map['type'] ?? "",
        user: map['user'] ?? "",
        like: map['like'] ?? 0,
        comment: map['comment'] ?? 0,
        signalement: map['signalement'] ?? 0);
  }
}
