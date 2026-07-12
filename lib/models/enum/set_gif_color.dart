import 'package:flutter/material.dart';

class SetGifColor {
  // Fonction qui retourne le chemin du loader GIF en fonction de la couleur
  static String getGifPath(Color color) {
    // teinte rouge
    if (color == const Color.fromRGBO(204, 51, 51, 1)) {
      return "images/assets/gif_by_colors/k_loader_rouge_204.51.51.gif";
    } else if (color == const Color.fromRGBO(255, 102, 102, 1)) {
      return "images/assets/gif_by_colors/k_loader_rouge_255.102.102.gif";
    } else if (color == const Color.fromRGBO(255, 153, 153, 1)) {
      return "images/assets/gif_by_colors/k_loader_rouge_255.153.153.gif";
    }
    // teinte orange
    else if (color == const Color.fromRGBO(255, 153, 51, 1)) {
      return "images/assets/gif_by_colors/k_loader_orange_255.153.51.gif";
    } else if (color == const Color.fromRGBO(255, 187, 102, 1)) {
      return "images/assets/gif_by_colors/k_loader_orange_255.187.102.gif";
    } else if (color == const Color.fromRGBO(255, 204, 153, 1)) {
      return "images/assets/gif_by_colors/k_loader_orange_255.204.153.gif";
    }
    // teinte verte
    else if (color == const Color.fromRGBO(72, 119, 91, 1)) {
      return "images/assets/gif_by_colors/k_loader_vert_72.119.91.gif";
    } else if (color == const Color.fromRGBO(102, 153, 122, 1)) {
      return "images/assets/gif_by_colors/k_loader_vert_102.153.122.gif";
    } else if (color == const Color.fromRGBO(132, 170, 143, 1)) {
      return "images/assets/gif_by_colors/k_loader_vert_132.170.143.gif";
    }
    // teinte bleue
    else if (color == const Color.fromRGBO(0, 51, 102, 1)) {
      return "images/assets/gif_by_colors/k_loader_bleue_0.51.102.gif";
    } else if (color == const Color.fromRGBO(51, 102, 153, 1)) {
      return "images/assets/gif_by_colors/k_loader_bleue_51.102.153.gif";
    } else if (color == const Color.fromRGBO(102, 153, 204, 1)) {
      return "images/assets/gif_by_colors/k_loader_bleue_102.153.204.gif";
    }
    // teinte Pourpres
    else if (color == const Color.fromRGBO(102, 51, 102, 1)) {
      return "images/assets/gif_by_colors/k_loader_pourpre_102.51.102.gif";
    } else if (color == const Color.fromRGBO(153, 102, 153, 1)) {
      return "images/assets/gif_by_colors/k_loader_pourpre_153.102.153.gif";
    } else if (color == const Color.fromRGBO(204, 153, 204, 1)) {
      return "images/assets/gif_by_colors/k_loader_pourpre_204.153.204.gif";
    }
    // teinte Roses
    else if (color == const Color.fromRGBO(255, 102, 153, 1)) {
      return "images/assets/gif_by_colors/k_loader_rose_255.102.153.gif";
    } else if (color == const Color.fromRGBO(255, 153, 187, 1)) {
      return "images/assets/gif_by_colors/k_loader_rose_255.153.187.gif";
    } else if (color == const Color.fromRGBO(255, 204, 229, 1)) {
      return "images/assets/gif_by_colors/k_loader_rose_255.204.229.gif";
    }
    // par default
    else {
      return "images/assets/gif_by_colors/k_loader_vert_72.119.91.gif";
    }
  }
}
