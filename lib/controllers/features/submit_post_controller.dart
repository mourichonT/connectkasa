import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';

class SubmitPostController {
  static submitForm(
      String uid,
      String idPost,
      String selectedLabel,
      String imagePath,
      TextEditingController title,
      TextEditingController desc,
      bool anonymPost,
      String docRes,
      {String? localisation,
      String? etage,
      Set<String>? element,
      List<String>? participants}) {
    // Créer une instance de DataBasesServices
    DataBasesPostServices dataBasesPostServices = DataBasesPostServices();
    String location = "";
    if (localisation != null &&
        etage != null &&
        element != null &&
        element.isNotEmpty) {
      location = "$localisation / $etage / ${element.join('- ')}";
    }

    // Créer un nouvel objet Post
    Post newPost = Post(
        id: idPost, // Vous devez générer un ID unique pour chaque post
        description: desc.text,
        emplacement: location,
        subtype: "",
        pathImage: imagePath,
        refResidence: docRes,
        statu: selectedLabel == "sinistres" ? "En attente" : "",
        timeStamp: Timestamp.now(),
        title: title.text,
        type: selectedLabel,
        user: uid, // Remplacer par l'utilisateur actuel
        like: [], // Vous pouvez initialiser avec une liste vide
        signalement: [], // Vous pouvez initialiser avec une liste vide
        hideUser: anonymPost,
        participants: []);

    // Appeler la méthode addPost pour ajouter le nouveau post
    dataBasesPostServices.addPost(newPost, docRes);
  }
}
