import 'package:cloud_firestore/cloud_firestore.dart';

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
  String location_element;
  String location_details;
  String location_floor;
  List<String> like;
  List<Post> signalement;
  bool hideUser;
  List<String>? participants;
  String? price;

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
    this.location_element = "",
    this.location_details = "", // Nouvel attribut
    this.location_floor = "", // Nouvel attribut
    this.like = const [],
    this.signalement = const [],
    required this.hideUser,
    this.participants = const [],
    this.price = "",
  }) {
    _pathImage = pathImage;
    _statu = statu;
    _subtype = subtype;
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

  String setParticipant(participantCount) {
    if (participantCount > 1) {
      return "Participants ( $participantCount )";
    } else {
      return "Participant ( $participantCount )";
    }
  }

  String setPrice(price) {
    if (price == "0") {
      return "Gratuit";
    } else if (price == "1") {
      return "$price Kasa";
    } else {
      return "$price Kasas";
    }
  }

  String setSignalement(postCount) {
    if (postCount > 1) {
      return "$postCount Signalements";
    } else {
      return "$postCount Signalement";
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
    List<dynamic>? participantsList = map['participants'];
    List<String> convertedParticipantsList = [];
    if (participantsList != null) {
      for (var user in participantsList) {
        if (user is String) {
          convertedParticipantsList.add(user);
        }
      }
    }

    return Post(
      id: map['id'] ?? "",
      description: map['description'] ?? "",
      location_element:
          map['location_element'] ?? "", // Mise à jour du nom de l'attribut
      location_details: map['location_details'] ?? "", // Nouvel attribut
      location_floor: map['location_floor'] ?? "", // Nouvel attribut
      subtype: map['subtype'] ?? "",
      pathImage: map['pathImage'] ?? "",
      refResidence: map['refResidence'] ?? "",
      statu: map['statu'] ?? "",
      timeStamp: map['timeStamp'] ?? 0,
      title: map['title'] ?? "",
      type: map['type'] ?? "",
      user: map['user'] ?? "",
      like: convertedLikeList,
      signalement: (map['signalement'] as List<dynamic>? ?? [])
          .whereType<
              Map<String,
                  dynamic>>() // Filtrez les éléments qui ne sont pas des Map<String, dynamic>
          .map((signalementData) => Post.fromMap(signalementData))
          .toList(),
      hideUser: map['hideUser'],
      participants: convertedParticipantsList,
      price: map['price'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'location_element': location_element, // Mise à jour du nom de l'attribut
      'location_details': location_details, // Nouvel attribut
      'location_floor': location_floor, // Nouvel attribut
      'subtype': subtype,
      'pathImage': pathImage,
      'refResidence': refResidence,
      'statu': statu,
      'timeStamp': timeStamp,
      'title': title,
      'type': type,
      'user': user,
      'like': like,
      'signalement': signalement.map((post) => post.toMap()).toList(),
      'hideUser': hideUser,
      'participants': participants,
      'price': price
    };
  }
}
