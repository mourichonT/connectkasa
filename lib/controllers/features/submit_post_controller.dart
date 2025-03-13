import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubmitPostController {
  static submitForm(
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
      String? backgroundColor,
      String? backgroundImage,
      int? price,
      List<String>? element,
      List<String>? participants,
      List<String>? eventType,
      double? fontSize,
      String? fontWeight,
      String? fontColor,
      String? fontStyle,
      Timestamp? eventDate,
      String? prestaName}) {
    // Créer une instance de DataBasesServices
    DataBasesPostServices dataBasesPostServices = DataBasesPostServices();

    // Créer un nouvel objet Post
    Post newPost = Post(
      id: idPost, // Vous devez générer un ID unique pour chaque post
      description: desc?.text ?? "",
      location_element: localisation ?? "",
      location_details: element ?? [],
      location_floor: etage ?? "",
      subtype: subtype ?? "",
      price: price ?? 0,
      pathImage: imagePath ?? "",
      refResidence: docRes,
      statu: selectedLabel == "sinistres" ? "En attente" : "",
      timeStamp: Timestamp.now(),
      title: title?.text ?? "",
      type: selectedLabel,
      user: uid, // Remplacer par l'utilisateur actuel
      like: [], // Vous pouvez initialiser avec une liste vide
      signalement: [], // Vous pouvez initialiser avec une liste vide
      hideUser: anonymPost ?? false,
      participants: participants ?? [],
      eventType: eventType ?? [],
      backgroundColor: backgroundColor ?? "",
      backgroundImage: backgroundImage ?? "",
      fontSize: fontSize ?? 20.0,
      fontWeight: fontWeight ?? "",
      fontColor: fontColor ?? "",
      fontStyle: fontStyle ?? "",
      eventDate: eventDate,
      prestaName: prestaName,
    );

    // Appeler la méthode addPost pour ajouter le nouveau post
    dataBasesPostServices.addPost(newPost, docRes);
  }

  static Future<void> addPostAfterChecking(
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
      String? backgroundColor,
      String? backgroundImage,
      int? price,
      List<String>? element,
      List<String>? participants,
      List<String>? eventType,
      double? fontSize,
      String? fontWeight,
      String? fontColor,
      String? fontStyle,
      Timestamp? eventDate,
      String? prestaName}) async {
    DataBasesPostServices dataBasesPostServices = DataBasesPostServices();
    // Appeler la Cloud Function pour vérifier les doublons
    print("Appel à la Cloud Function pour vérifier les doublons...");

    final duplicateResponse = await checkDuplicatePost(
        docRes: docRes,
        postId: idPost,
        title: title?.text ?? "",
        description: desc?.text ?? "");
    print("Réponse de la Cloud Function : ${duplicateResponse['status']}");

    // Vérifier le résultat de la Cloud Function
    if (duplicateResponse['status'] == "duplicate_found") {
      print("Doublon trouvé. ID du doublon : ${duplicateResponse['post_id']}");

      Post newSignalement = Post(
        id: idPost,
        description: desc?.text ?? "",
        location_element: localisation ?? "",
        location_details: element ?? [],
        location_floor: etage ?? "",
        subtype: subtype ?? "",
        price: price ?? 0,
        pathImage: imagePath ?? "",
        refResidence: docRes,
        statu: selectedLabel == "sinistres" ? "En attente" : "",
        timeStamp: Timestamp.now(),
        title: title?.text ?? "",
        type: selectedLabel,
        user: uid,
        like: [],
        signalement: [],
        hideUser: anonymPost ?? false,
        participants: participants ?? [],
        eventType: eventType ?? [],
        backgroundColor: backgroundColor ?? "",
        backgroundImage: backgroundImage ?? "",
        fontSize: fontSize ?? 20.0,
        fontWeight: fontWeight ?? "",
        fontColor: fontColor ?? "",
        fontStyle: fontStyle ?? "",
        eventDate: eventDate,
        prestaName: prestaName,
      );
      dataBasesPostServices.addSignalement(
          newSignalement, docRes, duplicateResponse['post_id']);
      print("Post est un doublon, signalement ajouté.");
    } else if (duplicateResponse['status'] == "post_not_found") {
      print("Post non trouvé. ID du post : ${duplicateResponse['post_id']}");
      // Ne pas procéder si le post n'est pas trouvé
    } else {
      print("Aucun doublon trouvé, création du nouveau post.");
      // Ajouter le post seulement si aucun doublon n'a été trouvé

      Post newPost = Post(
        id: idPost,
        description: desc?.text ?? "",
        location_element: localisation ?? "",
        location_details: element ?? [],
        location_floor: etage ?? "",
        subtype: subtype ?? "",
        price: price ?? 0,
        pathImage: imagePath ?? "",
        refResidence: docRes,
        statu: selectedLabel == "sinistres" ? "En attente" : "",
        timeStamp: Timestamp.now(),
        title: title?.text ?? "",
        type: selectedLabel,
        user: uid,
        like: [],
        signalement: [],
        hideUser: anonymPost ?? false,
        participants: participants ?? [],
        eventType: eventType ?? [],
        backgroundColor: backgroundColor ?? "",
        backgroundImage: backgroundImage ?? "",
        fontSize: fontSize ?? 20.0,
        fontWeight: fontWeight ?? "",
        fontColor: fontColor ?? "",
        fontStyle: fontStyle ?? "",
        eventDate: eventDate,
        prestaName: prestaName,
      );

      // Appeler la méthode addPost pour ajouter le nouveau post
      print("Ajout du nouveau post dans la base de données...");
      dataBasesPostServices.addPost(newPost, docRes);
      print("Post ajouté avec succès.");
    }
  }

  static Future<Map<String, dynamic>> checkDuplicatePost(
      {required String docRes,
      required String postId,
      required String title,
      required String description}) async {
    final url = Uri.parse(
        "https://check-similar-post-325705345982.us-central1.run.app"); // Remplacer par l'URL de ta Cloud Function
    // Envoi de la requête à la Cloud Function
    print("Envoi de la requête à la Cloud Function...");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "params": {
            "docRes": docRes,
            "postId": postId,
            "title": title,
            "description": description,
          }
        }),
      );

      // Vérification du code de réponse HTTP
      if (response.statusCode == 200) {
        print("Réponse de la Cloud Function reçue avec succès.");

        final data = json.decode(response.body);
        print("Contenu de la réponse de la Cloud Function : $data");

        // Vérification de la présence des données nécessaires dans la réponse
        if (data.containsKey('status')) {
          return {
            'status': data['status'] ?? "new_post_created",
            'post_id': data['post_id'] ?? "",
          };
        } else {
          print("La réponse ne contient pas le statut attendu.");
          return {
            'status':
                "new_post_created", // Valeur par défaut si statut non trouvé
            'post_id': ""
          };
        }
      } else {
        // Si la réponse n'est pas un code 200, gérer l'erreur
        print("Erreur avec la Cloud Function. Code: ${response.statusCode}");
        print("Message d'erreur : ${response.body}");
        return {
          'status': "new_post_created", // Valeur par défaut si erreur
          'post_id': ""
        };
      }
    } catch (e) {
      // Gestion des erreurs liées à la requête (ex : pas de connexion réseau, timeout, etc.)
      print("Erreur lors de l'envoi de la requête : $e");
      return {
        'status': "new_post_created", // Valeur par défaut en cas d'erreur
        'post_id': ""
      };
    }
  }

  static UpdatePost(
      {required String uid,
      required String idPost,
      required String selectedLabel,
      required String? imagePath,
      String? title,
      required String? desc,
      required bool anonymPost,
      required String docRes,
      required List<String>? like,
      String? statu,
      int? price,
      String? subtype,
      String? localisation,
      String? etage,
      List<String>? element,
      List<String>? participants,
      List<String>? eventType,
      String? backgroundColor,
      String? backgroundImage,
      double? fontSize,
      String? fontWeight,
      String? fontColor,
      String? fontStyle,
      String? prestaName}) {
    DataBasesPostServices dataBasesPostServices = DataBasesPostServices();

    // Créer un nouvel objet Post
    Post updatePost = Post(
        id: idPost, // Vous devez générer un ID unique pour chaque post
        description: desc ?? "",
        location_element: localisation ?? "",
        location_details: element ?? [],
        location_floor: etage ?? "",
        subtype: subtype ?? "",
        pathImage: imagePath ?? "",
        refResidence: docRes,
        like: like ?? [],
        statu: statu ?? "",
        timeStamp: Timestamp.now(),
        title: title ?? "",
        type: selectedLabel,
        user: uid, // Remplacer par l'utilisateur actuel
        hideUser: anonymPost,
        price: price ?? 0,
        participants: participants ?? [],
        eventType: eventType ?? [],
        backgroundColor: backgroundColor ?? "",
        backgroundImage: backgroundImage ?? "",
        fontSize: fontSize ?? 20.0,
        fontWeight: fontWeight ?? "",
        fontColor: fontColor ?? "",
        fontStyle: fontColor ?? "",
        prestaName: prestaName);

    // Appeler la méthode addPost pour ajouter le nouveau post
    dataBasesPostServices.updatePost(updatePost, docRes, idPost);
  }
}
