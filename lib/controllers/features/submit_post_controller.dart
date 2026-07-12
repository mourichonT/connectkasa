import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/post_style.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/core/utils/text_formatting.dart';

class SubmitPostController {
  static Post _buildPost({
    required String uid,
    required String idPost,
    required String selectedLabel,
    required String docRes,
    String? imagePath,
    TextEditingController? title,
    TextEditingController? desc,
    bool? anonymPost,
    String? localisation,
    String? etage,
    String? subtype,
    PostStyle? style,
    int? price,
    List<String>? element,
    List<String>? participants,
    List<String>? eventType,
    Timestamp? eventDate,
    String? prestaName,
  }) {
    return Post(
      id: idPost,
      description: capitalizeFirstLetter(desc?.text ?? ""),
      locationElement: localisation ?? "",
      locationDetails: element ?? [],
      locationFloor: etage ?? "",
      subtype: subtype ?? "",
      price: price ?? 0,
      pathImage: imagePath ?? "",
      refResidence: docRes,
      statu: selectedLabel == "sinistres" ? "En attente" : "",
      timeStamp: Timestamp.now(),
      title: capitalizeFirstLetter(title?.text ?? ""),
      type: selectedLabel,
      user: uid,
      like: [],
      signalement: [],
      hideUser: anonymPost ?? false,
      participants: participants ?? [],
      eventType: eventType ?? [],
      style: style ?? PostStyle(),
      eventDate: eventDate,
      prestaName: prestaName,
    );
  }

  static Future<void> submitForm(
      {required String uid,
      required String idPost,
      required String selectedLabel,
      String? imagePath,
      TextEditingController? title,
      TextEditingController? desc,
      bool? anonymPost,
      required String docRes,
      String? localisation,
      String? etage,
      String? subtype,
      PostStyle? style,
      int? price,
      List<String>? element,
      List<String>? participants,
      List<String>? eventType,
      Timestamp? eventDate,
      String? prestaName}) async {
    IPostRepository dataBasesPostServices = FirestorePostRepository();

    final newPost = _buildPost(
      uid: uid,
      idPost: idPost,
      selectedLabel: selectedLabel,
      docRes: docRes,
      imagePath: imagePath,
      title: title,
      desc: desc,
      anonymPost: anonymPost,
      localisation: localisation,
      etage: etage,
      subtype: subtype,
      style: style,
      price: price,
      element: element,
      participants: participants,
      eventType: eventType,
      eventDate: eventDate,
      prestaName: prestaName,
    );

    await dataBasesPostServices
        .addPost(newPost, docRes)
        .then((result) => result.when(
            success: (_) {}, failure: (error) => throw error));
  }

  static Future<void> addPostAfterChecking({
    required String uid,
    required String idPost,
    required String selectedLabel,
    String? imagePath,
    TextEditingController? title,
    TextEditingController? desc,
    bool? anonymPost,
    required String docRes,
    String? localisation,
    String? etage,
    String? subtype,
    PostStyle? style,
    int? price,
    List<String>? element,
    List<String>? participants,
    List<String>? eventType,
    Timestamp? eventDate,
    String? prestaName,
  }) async {
    IPostRepository dataBasesPostServices = FirestorePostRepository();

    final duplicateResponse = await checkDuplicatePost(
      docRes: docRes,
      postId: idPost,
      title: title?.text ?? "",
      description: desc?.text ?? "",
      locationElement: localisation ?? "",
      locationFloor: etage ?? "",
    );

    final post = _buildPost(
      uid: uid,
      idPost: idPost,
      selectedLabel: selectedLabel,
      docRes: docRes,
      imagePath: imagePath,
      title: title,
      desc: desc,
      anonymPost: anonymPost,
      localisation: localisation,
      etage: etage,
      subtype: subtype,
      style: style,
      price: price,
      element: element,
      participants: participants,
      eventType: eventType,
      eventDate: eventDate,
      prestaName: prestaName,
    );

    if (duplicateResponse['status'] == "duplicate_found") {
      appLog("Doublon trouvé. ID du doublon : ${duplicateResponse['post_id']}");
      await dataBasesPostServices
          .addSignalement(post, docRes, duplicateResponse['post_id'])
          .then((result) => result.when(
              success: (_) {}, failure: (error) => throw error));
      appLog("Post est un doublon, signalement ajouté.");
    } else if (duplicateResponse['status'] == "post_not_found") {
      appLog("Post non trouvé. ID du post : ${duplicateResponse['post_id']}");
      // Aucun ajout si post introuvable
    } else {
      appLog("Aucun doublon trouvé, création du nouveau post...");
      await dataBasesPostServices
          .addPost(post, docRes)
          .then((result) => result.when(
              success: (_) {}, failure: (error) => throw error));
      appLog("Post ajouté avec succès.");
    }
  }

  static Future<Map<String, dynamic>> checkDuplicatePost({
    required String docRes,
    required String postId,
    required String title,
    required String description,
    required String locationElement,
    required String locationFloor,
  }) async {
    final url = Uri.parse(
      "https://us-central1-konodal-dev.cloudfunctions.net/check_similar_post_OpenAI",
    );

    appLog("Envoi de la requête à la Cloud Function...");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "params": {
            "docRes": docRes,
            "postId": postId,
            "title": title,
            "description": description,
            "location_element": locationElement,
            "location_floor": locationFloor,
          }
        }),
      );

      if (response.statusCode == 200) {
        appLog("Réponse de la Cloud Function reçue avec succès.");
        final data = json.decode(response.body);
        appLog("Contenu de la réponse : $data");

        return {
          'status': data['status'] ?? "new_post_created",
          'post_id': data['post_id'] ?? "",
        };
      } else {
        appLog("Erreur avec la Cloud Function. Code: ${response.statusCode}");
        appLog("Message d'erreur : ${response.body}");
        return {
          'status': "new_post_created",
          'post_id': "",
        };
      }
    } catch (e) {
      appLog("Erreur lors de l'envoi de la requête : $e");
      return {
        'status': "new_post_created",
        'post_id': "",
      };
    }
  }

  // static Future<Map<String, dynamic>> checkDuplicatePost(
  //     {required String docRes,
  //     required String postId,
  //     required String title,
  //     required String description}) async {
  //   final url = Uri.parse(
  //       "https://check-similar-post-325705345982.us-central1.run.app"); // Remplacer par l'URL de ta Cloud Function
  //   // Envoi de la requête à la Cloud Function
  //   appLog("Envoi de la requête à la Cloud Function...");

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Accept": "application/json"
  //       },
  //       body: jsonEncode({
  //         "params": {
  //           "docRes": docRes,
  //           "postId": postId,
  //           "title": title,
  //           "description": description,
  //         }
  //       }),
  //     );

  //     // Vérification du code de réponse HTTP
  //     if (response.statusCode == 200) {
  //       appLog("Réponse de la Cloud Function reçue avec succès.");

  //       final data = json.decode(response.body);
  //       appLog("Contenu de la réponse de la Cloud Function : $data");

  //       // Vérification de la présence des données nécessaires dans la réponse
  //       if (data.containsKey('status')) {
  //         return {
  //           'status': data['status'] ?? "new_post_created",
  //           'post_id': data['post_id'] ?? "",
  //         };
  //       } else {
  //         appLog("La réponse ne contient pas le statut attendu.");
  //         return {
  //           'status':
  //               "new_post_created", // Valeur par défaut si statut non trouvé
  //           'post_id': ""
  //         };
  //       }
  //     } else {
  //       // Si la réponse n'est pas un code 200, gérer l'erreur
  //       appLog("Erreur avec la Cloud Function. Code: ${response.statusCode}");
  //       appLog("Message d'erreur : ${response.body}");
  //       return {
  //         'status': "new_post_created", // Valeur par défaut si erreur
  //         'post_id': ""
  //       };
  //     }
  //   } catch (e) {
  //     // Gestion des erreurs liées à la requête (ex : pas de connexion réseau, timeout, etc.)
  //     appLog("Erreur lors de l'envoi de la requête : $e");
  //     return {
  //       'status': "new_post_created", // Valeur par défaut en cas d'erreur
  //       'post_id': ""
  //     };
  //   }
  // }

  static Future<void> updatePost(
      {required String uid,
      required String idPost,
      required String selectedLabel,
      required String? imagePath,
      String? title,
      required String? desc,
      required bool anonymPost,
      required String docRes,
      required List<String>? like,
      Timestamp? timeStamp,
      Timestamp? declaredDate,
      String? statu,
      int? price,
      String? subtype,
      String? localisation,
      String? etage,
      List<String>? element,
      List<String>? participants,
      List<String>? eventType,
      PostStyle? style,
      String? prestaName}) async {
    IPostRepository dataBasesPostServices = FirestorePostRepository();

    // Créer un nouvel objet Post
    Post updatePost = Post(
        id: idPost, // Vous devez générer un ID unique pour chaque post
        description: desc ?? "",
        locationElement: localisation ?? "",
        locationDetails: element ?? [],
        locationFloor: etage ?? "",
        subtype: subtype ?? "",
        pathImage: imagePath ?? "",
        refResidence: docRes,
        like: like ?? [],
        statu: statu ?? "",
        timeStamp: timeStamp ?? Timestamp.now(),
        title: title ?? "",
        type: selectedLabel,
        user: uid, // Remplacer par l'utilisateur actuel
        hideUser: anonymPost,
        price: price ?? 0,
        participants: participants ?? [],
        eventType: eventType ?? [],
        style: style ?? PostStyle(),
        declaredDate: declaredDate,
        prestaName: prestaName);

    // Appeler la méthode updatePost pour mettre à jour le post
    await dataBasesPostServices
        .updatePost(updatePost, docRes, idPost)
        .then((result) => result.when(
            success: (_) {}, failure: (error) => throw error));
  }
}
