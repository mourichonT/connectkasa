import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/cupertino.dart';

import '../../vues/components/post_widget.dart';

class DatasPosts {
  Post post1 = Post(
      numResidence: "00001",
      numUser: "UOOOO1",
      type: "Sinistre",
      date: "06/01/2023",
      statu: "En attente",
      pathImage: "images/fuite1.jpg",
      title: "Fuite d’eau dans le Parking",
      description: "Ce matin une fuite a été constatée au niveau du sous terrain",
      like: 0,
      comment: 2,
      signalement: 1
  );

  Post post2 = Post(
      numResidence:"00001",
      type: "Incivilité",
      date: "05/01/2023",
      pathImage: "images/incivilite.jpg",
      title: "Dechet Mecanique",
      description: "Quand vous faites de la mécanique, il est bon de nettoyer derrière vous",
      numUser: 'UOOOO2'
  );

  Post post3 = Post(
      numResidence:"00002",
      type: "Sinistre",
      date: "04/01/2023",
      pathImage: "images/infiltration.jpg",
      title: "Infiltration plafond",
      description: "Ce matin de l'eau coulait du plafond du Bat 1 ",
      numUser: 'UOOOO3'
  );

  List<Post> posts (){
    return [
      post1, post2, post3
    ];
  }

}

