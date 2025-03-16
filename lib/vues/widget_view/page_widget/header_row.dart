import 'package:connect_kasa/controllers/features/Icon_modify_or_delette.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart'; // Assure-toi que ton style est importé correctement

// ignore: must_be_immutable
class CustomHeaderRow extends StatelessWidget {
  // Texte à afficher
  final Color? colorStatut; // Couleur du texte
  final Post post;
  List<List<String>> typeList = TypeList().typeDeclaration();
  final bool isCsMember;
  final Function updatePostsList;

  CustomHeaderRow(
      {super.key,
      this.colorStatut,
      required this.post,
      required this.isCsMember,
      required this.updatePostsList});

  String getType(Post post) {
    for (var type in typeList) {
      // Vous pouvez accéder à chaque type avec type[0] pour le nom et type[1] pour la valeur
      var typeName = type[0];
      var typeValue = type[1];
      // Vous devez probablement utiliser le post ici pour récupérer la valeur de type
      if (post.type == typeValue) {
        return typeName;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5, left: 10, right: 10),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Espace entre les éléments
        crossAxisAlignment: CrossAxisAlignment
            .center, // Aligner verticalement les éléments au centre
        children: [
          MyTextStyle.lotName(getType(post), Colors.black87, SizeFont.h3.size),
          Spacer(),
          MyTextStyle.statuColor(post.statu!, colorStatut),
          Visibility(
              visible: isCsMember,
              child: IconModifyOrDelette(post, context, updatePostsList))
        ],
      ),
    );
  }
}
