import 'package:konodal/controllers/features/icon_modify_or_delette.dart';
import 'package:konodal/models/enum/event_type.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:flutter/material.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart'; // Assure-toi que ton style est importé correctement

// ignore: must_be_immutable
class CustomHeaderRow extends StatelessWidget {
  final Lot lot;
  // Texte à afficher
  final Color? colorStatut; // Couleur du texte
  final Post post;
  List<List<String>> typeList = TypeList().typeDeclaration();
  final bool isCsMember;
  final Function updatePostsList;

  CustomHeaderRow({
    super.key,
    this.colorStatut,
    required this.post,
    required this.isCsMember,
    required this.updatePostsList,
    required this.lot,
  });

  // Une intervention (type "events") n'a pas de champ statut (le workflow à
  // 4 états sinistre/incivilité ne s'applique pas ici) : 3 états dérivés des
  // booléens termine/reporte du post (posés uniquement par les Cloud
  // Functions - create_shared_rapport/reschedule_shared_intervention),
  // jamais par l'app. Purement informatif, pas de Stepper.
  String _eventStatusLabel(Post post) {
    if (post.termine) return "Terminé";
    if (post.reporte) return "Reporté";
    return "Programmé";
  }

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

  // Un événement participatif (EventType.evenement) n'a pas de workflow
  // d'intervention (pas de prestataire à programmer/reporter) : le badge
  // Programmé/Reporté/Terminé n'a de sens que pour une intervention
  // (EventType.prestation).
  bool get _isParticipativeEvent =>
      post.type == "events" &&
      (post.eventType?.contains(EventType.evenement.value) ?? false);

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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: MyTextStyle.lotName(
                getType(post), Colors.black87, SizeFont.h3.size),
          ),
          Spacer(),
          Visibility(
            visible: !_isParticipativeEvent,
            child: MyTextStyle.statuColor(
                post.type == "events" ? _eventStatusLabel(post) : post.statut!,
                colorStatut),
          ),
          Visibility(
              visible: isCsMember,
              child: iconModifyOrDelette(post, lot, context, updatePostsList)),
        ],
      ),
    );
  }
}
