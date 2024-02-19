import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class Post {
  String id;
  String refResidence;
  String user;
  String type;
  String _subtype = "";
  Timestamp timeStamp;
  String _statu = "";
  String _pathImage = "";
  String title;
  String description;
  List<String> like;
  int signalement;

  Post({
    required this.id,
    required this.refResidence,
    required this.user,
    required this.type,
    String subtype = "",
    required this.timeStamp,
    String statu = "",
    String pathImage = "",
    required this.title,
    required this.description,
    this.like = const [],
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

  String setLike(likeCount) {
    //  final likeCount = like.length;
    if (likeCount > 1) {
      return "$likeCount Likes";
    } else {
      return "$likeCount Like";
    }
  }

  String setComments(commentCount) {
    if (commentCount > 1) {
      return "$commentCount Commentaires";
    } else {
      return "$commentCount Commentaire";
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
    List<dynamic>? likeList = map['like'];
    List<String> convertedLikeList = [];
    if (likeList != null) {
      for (var like in likeList) {
        if (like is String) {
          convertedLikeList.add(like);
        }
      }
    }

    return Post(
      id: map['id'] ?? "",
      description: map['description'] ?? "",
      subtype: map['subtype'] ?? "",
      pathImage: map['pathImage'] ?? "",
      refResidence: map['refResidence'] ?? "",
      statu: map['statu'] ?? "",
      timeStamp: map['timeStamp'] ?? 0,
      title: map['title'] ?? "",
      type: map['type'] ?? "",
      user: map['user'] ?? "",
      like: convertedLikeList,
      signalement: map['signalement'] ?? 0,
    );
  }
}
