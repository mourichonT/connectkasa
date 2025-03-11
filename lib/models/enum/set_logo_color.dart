import 'package:flutter/material.dart';

class SetLogoColor {
  // Fonction qui retourne le chemin du logo en fonction de la couleur
  static String getLogoPath(Color color) {
    // Exemple de mapping entre couleur et chemin de logo
    // teinte rouge
    if (color == const Color.fromRGBO(204, 51, 51, 1)) {
      return "images/assets/logo_by_colors/logoRouge204.51.51.png";
    } else if (color == const Color.fromRGBO(255, 102, 102, 1)) {
      return "images/assets/logo_by_colors/logoRouge255.102.102.png";
    } else if (color == const Color.fromRGBO(255, 153, 153, 1)) {
      return "images/assets/logo_by_colors/logoRouge255.153.153.png";
    }
    // teinte orange
    else if (color == const Color.fromRGBO(255, 153, 51, 1)) {
      return "images/assets/logo_by_colors/logoOrange255.153.51.png";
    } else if (color == const Color.fromRGBO(255, 187, 102, 1)) {
      return "images/assets/logo_by_colors/logoOrange255.187.102.png";
    } else if (color == const Color.fromRGBO(255, 204, 153, 1)) {
      return "images/assets/logo_by_colors/logoOrange255.204.153.png";
    }
    // teinte verte
    else if (color == const Color.fromRGBO(72, 119, 91, 1)) {
      return "images/assets/logo_by_colors/logoVert72.119.91.png";
    } else if (color == const Color.fromRGBO(102, 153, 122, 1)) {
      return "images/assets/logo_by_colors/logoVert102.153.122.png";
    } else if (color == const Color.fromRGBO(132, 170, 143, 1)) {
      return "images/assets/logo_by_colors/logoVert132.170.143.png";
    }
    // teinte bleue
    else if (color == const Color.fromRGBO(0, 51, 102, 1)) {
      return "images/assets/logo_by_colors/logoBleue0.51.102.png";
    } else if (color == const Color.fromRGBO(51, 102, 153, 1)) {
      return "images/assets/logo_by_colors/logoBleue51.102.153.png";
    } else if (color == const Color.fromRGBO(102, 153, 204, 1)) {
      return "images/assets/logo_by_colors/logoBleue102.153.204.png";
    }
    // teinte Pourpres
    else if (color == const Color.fromRGBO(102, 51, 102, 1)) {
      return "images/assets/logo_by_colors/logoPourpre102.51.102.png";
    } else if (color == const Color.fromRGBO(153, 102, 153, 1)) {
      return "images/assets/logo_by_colors/logoPourpre153.102.153.png";
    } else if (color == const Color.fromRGBO(204, 153, 204, 1)) {
      return "images/assets/logo_by_colors/logoPourpre204.153.204.png";
    }
    // teinte Roses
    else if (color == const Color.fromRGBO(255, 102, 153, 1)) {
      return "images/assets/logo_by_colors/logoRose255.102.153.png";
    } else if (color == const Color.fromRGBO(255, 153, 187, 1)) {
      return "images/assets/logo_by_colors/logoRose255.153.187.png";
    } else if (color == const Color.fromRGBO(255, 204, 229, 1)) {
      return "images/assets/logo_by_colors/logoRose255.204.229.png";
    }
    // par default
    else {
      return "images/assets/logo_by_colors/logoVert72.119.91.png"; // Logo par défaut si la couleur n'est pas spécifiée
    }
  }
}
