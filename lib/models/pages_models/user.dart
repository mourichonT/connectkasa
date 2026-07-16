import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/models/enum/notification_type.dart';

class User {
  String email;
  String _profilPic = "";
  // Regroupés sous 'user' côté Firestore (identité issue de la pièce
  // d'identité à l'inscription) ; getters/setters ci-dessous pour ne pas
  // casser les appelants existants qui lisent/écrivent .name/.surname/etc.
  // directement.
  String name;
  String surname;
  Timestamp birthday;
  String sex;
  String nationality;
  String placeOfborn;
  // Renommé depuis informationsCorrectes (bolted-on hors modèle avant ce
  // refactor) : l'utilisateur a confirmé que les infos extraites par l'OCR
  // de sa pièce d'identité (step0.dart) sont correctes.
  bool isInfoCorrect;
  String uid;
  Timestamp? createdDate;
  bool isApproved;
  bool privacyPolicy;
  Map<String, bool> notificationPrefs;
  // 'utilisateur' | 'professionnel' | 'superAdmin' - cette app (résident)
  // ne crée jamais que des comptes 'utilisateur' ; les deux autres types
  // sont créés hors-app (futur backoffice web) et n'ont pas leur place
  // dans cette interface, cf. LoginTransitionPage qui bloque l'accès si
  // ce n'est pas 'utilisateur'. Verrouillé côté firestore.rules comme
  // isApproved (non modifiable par le client une fois créé).
  String accountType;

  // Regroupés sous 'profil' côté Firestore ; getters/setters ci-dessous.
  String? pseudo;
  String? bio;
  bool private;
  // Numéro de contact du compte (saisi manuellement, aucune pièce
  // d'identité ne le fournit) - modifiable depuis "Modifier mes
  // informations", à ne pas confondre avec une adresse ou une autre donnée
  // propre à un dossier de location particulier.
  String phone;
  // Motif de refus d'identité, saisi par un Super Admin depuis le backoffice
  // web (konodal_bo) quand isApproved est mis/remis à false après un refus
  // explicite (par opposition à "pas encore examiné"). Jamais réécrit par
  // cette app : volontairement absent de toMap() pour ne pas l'écraser au
  // premier merge d'un profil résident (cf. commentaire toMap() ci-dessous).
  final String? rejectionReason;

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
    this.pseudo,
    this.private = true,
    required this.isApproved,
    this.createdDate,
    this.bio,
    this.phone = "",
    this.isInfoCorrect = false,
    this.accountType = 'utilisateur',
    this.rejectionReason,
    Map<String, bool>? notificationPrefs,
  }) : notificationPrefs = notificationPrefs ?? NotificationType.defaultPrefs {
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
    final userGroup = (map['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final profilGroup = (map['profil'] as Map?)?.cast<String, dynamic>() ?? {};

    return User(
      privacyPolicy: map['privacyPolicy'] ?? false,
      email: map['email'] ?? "",
      profilPic: profilGroup['profilPic'] ?? "",
      isApproved: map['isApproved'] ?? false,
      createdDate: map['createdDate'] != null
          ? map['createdDate'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(0),
      name: userGroup['name'] ?? "",
      surname: userGroup['surname'] ?? "",
      birthday: userGroup['birthday'] != null
          ? userGroup['birthday'] as Timestamp
          : Timestamp.fromMillisecondsSinceEpoch(0),
      sex: userGroup['sex'] ?? "",
      nationality: userGroup['nationality'] ?? "",
      placeOfborn: userGroup['placeOfborn'] ?? "",
      isInfoCorrect: userGroup['isInfoCorrect'] ?? false,
      accountType: map['accountType'] ?? 'utilisateur',
      rejectionReason: map['rejectionReason'],
      pseudo: profilGroup['pseudo'] ?? "",
      uid: map['uid'] ?? "",
      bio: profilGroup['bio'] ?? "",
      phone: profilGroup['phone'] ?? "",
      private: profilGroup['private'] ?? false,
      // Fusionne avec les valeurs par défaut (tout activé) pour couvrir les
      // utilisateurs existants qui n'ont pas encore ce champ, ou les
      // nouveaux types de notification ajoutés après leur inscription.
      notificationPrefs: {
        ...NotificationType.defaultPrefs,
        ...(map['notificationPrefs'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as bool)),
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'privacyPolicy': privacyPolicy,
      'isApproved': isApproved,
      'accountType': accountType,
      'createdDate': createdDate,
      'uid': uid,
      'email': email,
      'notificationPrefs': notificationPrefs,
      'user': {
        'name': name,
        'surname': surname,
        'birthday': birthday,
        'sex': sex,
        'nationality': nationality,
        'placeOfborn': placeOfborn,
        'isInfoCorrect': isInfoCorrect,
      },
      'profil': {
        'pseudo': pseudo,
        'bio': bio,
        'private': private,
        'profilPic': profilPic,
        'phone': phone,
      },
    };
  }
}
