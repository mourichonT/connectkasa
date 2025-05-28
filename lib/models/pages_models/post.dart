import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String id;
  String refResidence;
  String user;
  String type;
  String _subtype = "";
  Timestamp timeStamp;
  Timestamp? eventDate;
  Timestamp? declaredDate;
  String _statu = "";
  String _pathImage = "";
  String title;
  String description;
  String location_element;
  List<String>? location_details;
  String location_floor;
  List<String>? like;
  List<Post> signalement;
  bool hideUser;
  List<String>? participants;
  List<String>? eventType;
  int? price;
  String? backgroundColor;
  String? backgroundImage;
  double? fontSize;
  String? fontWeight;
  String? fontColor;
  String? fontStyle;
  String? prestaName;

  Post(
      {required this.id,
      required this.refResidence,
      required this.user,
      required this.type,
      String subtype = "",
      required this.timeStamp,
      this.eventDate,
      this.declaredDate,
      String statu = "",
      String pathImage = "",
      required this.title,
      required this.description,
      this.location_element = "",
      this.location_details = const [], // Nouvel attribut
      this.location_floor = "", // Nouvel attribut
      this.like = const [],
      this.signalement = const [],
      required this.hideUser,
      this.participants = const [],
      this.eventType = const [],
      this.price = 0,
      this.backgroundColor,
      this.backgroundImage,
      this.prestaName,
      this.fontSize,
      this.fontWeight,
      this.fontColor,
      this.fontStyle}) {
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

  String? get statu => _statu;
  set statu(String? value) {
    _statu = value ?? ""; // Valeur par défaut si null
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
      return "Participants ($participantCount)";
    } else {
      return "Participant ($participantCount)";
    }
  }

  String setPrice(price) {
    if (price == 0) {
      return "Gratuit";
    } else if (price == 1) {
      return "$price €";
    } else {
      return "$price €";
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
    List<dynamic>? detailsList = map['location_details'];
    List<String> convertLocationDetails = [];
    if (detailsList != null) {
      for (var detail in detailsList) {
        if (detail is String) {
          convertLocationDetails.add(detail);
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

    List<dynamic>? eventTypeList = map['eventType'];
    List<String> convertedEventTyeList = [];
    if (eventTypeList != null) {
      for (var eventTypeSelected in eventTypeList) {
        if (eventTypeSelected is String) {
          convertedEventTyeList.add(eventTypeSelected);
        }
      }
    }

    return Post(
      id: map['id'] ?? "",
      description: map['description'] ?? "",
      location_element:
          map['location_element'] ?? "", // Mise à jour du nom de l'attribut
      location_details: convertLocationDetails, // Nouvel attribut
      location_floor: map['location_floor'] ?? "", // Nouvel attribut
      subtype: map['subtype'] ?? "",
      pathImage: map['pathImage'] ?? "",
      refResidence: map['refResidence'] ?? "",
      statu: map['statu'] ?? "",
      timeStamp: map['timeStamp'] ?? 0,
      eventDate:
          map['eventDate'] != null ? map['eventDate'] as Timestamp : null,
      declaredDate:
          map['declaredDate'] != null ? map['declaredDate'] as Timestamp : null,
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
      eventType: convertedEventTyeList,
      price: map['price'] ?? 0,
      backgroundColor: map['backgroundColor'],
      backgroundImage: map['backgroundImage'],
      fontColor: map['fontColor'],
      fontSize: map['fontSize'],
      fontWeight: map['fontWeight'],
      fontStyle: map['fontStyle'],
      prestaName: map['prestaName'],
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
      'eventType': eventType,
      'timeStamp': timeStamp,
      'eventDate': eventDate,
      if (declaredDate != null) 'declaredDate': declaredDate,
      'title': title,
      'type': type,
      'user': user,
      'like': like,
      'signalement': signalement.map((post) => post.toMap()).toList(),
      'hideUser': hideUser,
      'participants': participants,
      'price': price,
      'backgroundColor': backgroundColor,
      'backgroundImage': backgroundImage,
      'fontColor': fontColor,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'fontStyle': fontStyle,
      'prestaName': prestaName
    };
  }
}
