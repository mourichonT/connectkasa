import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/models/pages_models/post_style.dart';

class Post {
  String id;
  String refResidence;
  String user;
  String type;
  String _subtype = "";
  Timestamp creationDate;
  Timestamp? eventDate;
  Timestamp? declaredDate;
  String _statut = "";
  String _pathImage = "";
  // Un post n'a qu'un seul média (image OU vidéo, jamais les deux) : ce
  // champ précise le type de pathImage, car le fichier Storage lui-même
  // n'a pas d'extension dans son nom (juste un UUID) - impossible de le
  // déduire après coup depuis l'URL.
  bool isVideo;
  String title;
  String description;
  String locationElement;
  List<String>? locationDetails;
  String locationFloor;
  List<String>? like;
  List<Post> signalement;
  bool hideUser;
  List<String>? participants;
  List<String>? eventType;
  int? price;
  PostStyle? style;
  String? prestaName;
  // Id (business, pas doc Firestore) du post "events" que ce compte-rendu
  // (type "rapport") documente - écrit uniquement côté Cloud Function
  // (create_shared_rapport, functions_python/main.py), jamais par l'app.
  String? linkedEventId;
  // Id (business) du post "sinistres"/"incivilites" à l'origine de cette
  // intervention (type "events") ou de ce compte-rendu (type "rapport") -
  // absent si l'intervention n'a jamais été liée à une déclaration (cf.
  // create_shared_rapport : aucun sinistre requis). Écrit uniquement côté
  // Cloud Function, jamais par l'app.
  String? linkedSinistreId;
  // Statuts d'une intervention (type "events") : contrairement au workflow
  // sinistre/incivilité (_statut, 4 valeurs), une intervention a 3 états
  // (Programmé par défaut, Reporté, Terminé - cf. header_row.dart) posés
  // automatiquement par les Cloud Functions (create_shared_rapport pour
  // termine, reschedule_shared_intervention pour reporte), jamais par
  // l'app. reporte==true marque l'ANCIENNE intervention remplacée par une
  // nouvelle après reprogrammation - jamais les deux vrais en même temps
  // en pratique (une intervention reportée n'a pas de compte-rendu).
  bool termine;
  bool reporte;

  Post(
      {required this.id,
      required this.refResidence,
      required this.user,
      required this.type,
      String subtype = "",
      required this.creationDate,
      this.eventDate,
      this.declaredDate,
      String statut = "",
      String pathImage = "",
      this.isVideo = false,
      required this.title,
      required this.description,
      this.locationElement = "",
      this.locationDetails = const [], // Nouvel attribut
      this.locationFloor = "", // Nouvel attribut
      this.like = const [],
      this.signalement = const [],
      required this.hideUser,
      this.participants = const [],
      this.eventType = const [],
      this.price = 0,
      this.style,
      this.prestaName,
      this.linkedEventId,
      this.linkedSinistreId,
      this.termine = false,
      this.reporte = false}) {
    _pathImage = pathImage;
    _statut = statut;
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

  String? get statut => _statut;
  set statut(String? value) {
    _statut = value ?? ""; // Valeur par défaut si null
  }

  set newStatut(String? newStatut) {
    if (newStatut != "") {
      _statut = newStatut!;
    }
  }

  String setDate() => "Posté le $creationDate";

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
    // Nouveau format : sous-objets location/event/annonce. Ancien format
    // (documents déjà en base avant ce refactor) : champs à plat directement
    // sur le post - on les relit tels quels, sans migration de données
    // obligatoire avant déploiement (même principe que 'style' ci-dessous).
    final Map<String, dynamic> location =
        map['location'] is Map ? Map<String, dynamic>.from(map['location']) : map;
    final Map<String, dynamic> event =
        map['event'] is Map ? Map<String, dynamic>.from(map['event']) : map;
    final Map<String, dynamic> annonce =
        map['annonce'] is Map ? Map<String, dynamic>.from(map['annonce']) : map;
    final Map<String, dynamic> dates =
        map['dates'] is Map ? Map<String, dynamic>.from(map['dates']) : map;

    List<dynamic>? likeList = map['like'];
    List<String> convertedLikeList = [];
    if (likeList != null) {
      for (var like in likeList) {
        if (like is String) {
          convertedLikeList.add(like);
        }
      }
    }
    List<dynamic>? detailsList =
        location['locationDetails'] ?? map['location_details'];
    List<String> convertLocationDetails = [];
    if (detailsList != null) {
      for (var detail in detailsList) {
        if (detail is String) {
          convertLocationDetails.add(detail);
        }
      }
    }

    List<dynamic>? participantsList = event['participants'];
    List<String> convertedParticipantsList = [];
    if (participantsList != null) {
      for (var user in participantsList) {
        if (user is String) {
          convertedParticipantsList.add(user);
        }
      }
    }

    List<dynamic>? eventTypeList = event['eventType'];
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
      locationElement: location['locationElements'] ??
          map['location_element'] ??
          "", // Mise à jour du nom de l'attribut
      locationDetails: convertLocationDetails, // Nouvel attribut
      locationFloor: location['locationFloor'] ??
          map['location_floor'] ??
          "", // Nouvel attribut
      subtype: annonce['subType'] ?? map['subtype'] ?? "",
      pathImage: map['pathImage'] ?? "",
      isVideo: map['isVideo'] ?? false,
      refResidence: map['refResidence'] ?? "",
      statut: map['statut'] ?? map['statu'] ?? "",
      // creationDate : ancien nom "timeStamp", relu ici sous 3 formats -
      // dates.creationDate (nouveau), dates.timeStamp (déjà migré vers
      // "dates" mais pas encore renommé), timeStamp à plat (jamais migré).
      creationDate: dates['creationDate'] ?? dates['timeStamp'] ?? map['timeStamp'] ?? 0,
      eventDate: event['eventDate'] != null ? event['eventDate'] as Timestamp : null,
      declaredDate: dates['declaredDate'] != null
          ? dates['declaredDate'] as Timestamp
          : (map['declaredDate'] != null
              ? map['declaredDate'] as Timestamp
              : null),
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
      price: annonce['price'] ?? map['price'] ?? 0,
      // Nouveau format : style imbriqué. Ancien format (documents déjà en
      // base avant ce refactor) : champs à plat directement sur le post -
      // on les relit tels quels, sans migration de données nécessaire.
      style: map['style'] != null
          ? PostStyle.fromMap(Map<String, dynamic>.from(map['style']))
          : (map['backgroundColor'] != null ||
                  map['backgroundImage'] != null ||
                  map['fontColor'] != null ||
                  map['fontSize'] != null ||
                  map['fontWeight'] != null ||
                  map['fontStyle'] != null
              ? PostStyle.fromMap(map)
              : null),
      prestaName: event['prestaName'] ?? map['prestaName'],
      linkedEventId: map['linkedEventId'],
      linkedSinistreId: map['linkedSinistreId'],
      termine: map['termine'] ?? false,
      reporte: map['reporte'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final location = {
      if (locationDetails != null && locationDetails!.isNotEmpty)
        'locationDetails': locationDetails,
      if (locationFloor.isNotEmpty) 'locationFloor': locationFloor,
      if (locationElement.isNotEmpty) 'locationElements': locationElement,
    };
    final event = {
      if (eventDate != null) 'eventDate': eventDate,
      if (eventType != null && eventType!.isNotEmpty) 'eventType': eventType,
      if (participants != null && participants!.isNotEmpty)
        'participants': participants,
      if ((prestaName ?? '').isNotEmpty) 'prestaName': prestaName,
    };
    final annonce = {
      if ((subtype ?? '').isNotEmpty) 'subType': subtype,
      if (price != null && price != 0) 'price': price,
    };
    final dates = {
      'creationDate': creationDate,
      if (declaredDate != null) 'declaredDate': declaredDate,
    };

    return {
      'id': id,
      'description': description,
      if (location.isNotEmpty) 'location': location,
      if ((pathImage ?? '').isNotEmpty) 'pathImage': pathImage,
      if (isVideo) 'isVideo': isVideo,
      'refResidence': refResidence,
      if ((statut ?? '').isNotEmpty) 'statut': statut,
      if (event.isNotEmpty) 'event': event,
      'dates': dates,
      if (title.isNotEmpty) 'title': title,
      'type': type,
      'user': user,
      if (like != null && like!.isNotEmpty) 'like': like,
      if (signalement.isNotEmpty)
        'signalement': signalement.map((post) => post.toMap()).toList(),
      'hideUser': hideUser,
      if (annonce.isNotEmpty) 'annonce': annonce,
      if (style != null) 'style': style!.toMap(),
    };
  }

  /// Comme toMap(), mais pour un update() partiel : chaque champ optionnel
  /// est ciblé individuellement en notation pointée (ex: 'event.eventDate'),
  /// effacé via FieldValue.delete() quand vide plutôt que simplement omis -
  /// un update() ne touche jamais les clés absentes de la map, donc un champ
  /// vidé lors d'une modification (ex: prix retiré) resterait sinon figé en
  /// base avec son ancienne valeur. La notation pointée cible le champ
  /// imbriqué précis sans effacer les autres champs du même sous-objet
  /// (location/event/annonce).
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      'id': id,
      'description': description,
      'refResidence': refResidence,
      'dates.creationDate': creationDate,
      'type': type,
      'user': user,
      'hideUser': hideUser,
    };

    void setOrClear(String key, dynamic value, bool isEmpty) {
      map[key] = isEmpty ? FieldValue.delete() : value;
    }

    setOrClear('title', title, title.isEmpty);
    setOrClear('pathImage', pathImage, (pathImage ?? '').isEmpty);
    setOrClear('isVideo', isVideo, !isVideo);
    setOrClear('statut', statut, (statut ?? '').isEmpty);
    setOrClear('dates.declaredDate', declaredDate, declaredDate == null);
    setOrClear('like', like, like == null || like!.isEmpty);
    setOrClear('signalement', signalement.map((p) => p.toMap()).toList(),
        signalement.isEmpty);
    setOrClear('style', style?.toMap(), style == null);

    setOrClear('location.locationElements', locationElement,
        locationElement.isEmpty);
    setOrClear('location.locationDetails', locationDetails,
        locationDetails == null || locationDetails!.isEmpty);
    setOrClear(
        'location.locationFloor', locationFloor, locationFloor.isEmpty);

    setOrClear('event.eventDate', eventDate, eventDate == null);
    setOrClear('event.eventType', eventType,
        eventType == null || eventType!.isEmpty);
    setOrClear('event.participants', participants,
        participants == null || participants!.isEmpty);
    setOrClear(
        'event.prestaName', prestaName, (prestaName ?? '').isEmpty);

    setOrClear('annonce.subType', subtype, (subtype ?? '').isEmpty);
    setOrClear('annonce.price', price, price == null || price == 0);

    return map;
  }
}
