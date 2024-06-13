import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';

class SubmitPostController {
  static submitForm({
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
    String? backgroundColor,
    String? backgroundImage,
    int? price,
    List<String>? element,
    List<String>? participants,
    double? fontSize,
    String? fontWeight,
    String? fontColor,
    String? fontStyle,
  }) {
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
      participants: [],
      backgroundColor: backgroundColor ?? "",
      backgroundImage: backgroundImage ?? "",
      fontSize: fontSize ?? 20.0,
      fontWeight: fontWeight ?? "",
      fontColor: fontColor ?? "",
      fontStyle: fontStyle ?? "",
    );

    // Appeler la méthode addPost pour ajouter le nouveau post
    dataBasesPostServices.addPost(newPost, docRes);
  }

  static UpdatePost({
    required String uid,
    required String idPost,
    required String selectedLabel,
    required String? imagePath,
    TextEditingController? title,
    required TextEditingController desc,
    required bool anonymPost,
    required String docRes,
    required List<String>? like,
    int? price,
    String? subtype,
    String? localisation,
    String? etage,
    List<String>? element,
    List<String>? participants,
    String? backgroundColor,
    String? backgroundImage,
    double? fontSize,
    String? fontWeight,
    String? fontColor,
    String? fontStyle,
  }) {
    DataBasesPostServices dataBasesPostServices = DataBasesPostServices();

    // Créer un nouvel objet Post
    Post updatePost = Post(
      id: idPost, // Vous devez générer un ID unique pour chaque post
      description: desc.text,
      location_element: localisation ?? "",
      location_details: element ?? [],
      location_floor: etage ?? "",
      subtype: subtype ?? "",
      pathImage: imagePath ?? "",
      refResidence: docRes,
      like: like ?? [],
      statu: selectedLabel == "sinistres" ? "En attente" : "",
      timeStamp: Timestamp.now(),
      title: title?.text ?? "",
      type: selectedLabel,
      user: uid, // Remplacer par l'utilisateur actuel
      hideUser: anonymPost,
      price: price ?? 0,
      participants: participants ?? [],
      backgroundColor: backgroundColor ?? "",
      backgroundImage: backgroundImage ?? "",
      fontSize: fontSize ?? 20.0,
      fontWeight: fontWeight ?? "",
      fontColor: fontColor ?? "",
      fontStyle: fontColor ?? "",
    );

    // Appeler la méthode addPost pour ajouter le nouveau post
    dataBasesPostServices.updatePost(updatePost, docRes, idPost);
  }
}
