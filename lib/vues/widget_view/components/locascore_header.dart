import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/component_ls_header.dart';
import 'package:connect_kasa/vues/widget_view/components/rating_bar.dart';
import 'package:flutter/material.dart';

class LocascoreHeader extends StatelessWidget {
  final ratings = {
    5: 82,
    4: 13,
    3: 4,
    2: 1,
    1: 1,
  };

  LocascoreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            height: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotDesc("Note globale", SizeFont.para.size,
                    FontStyle.normal, FontWeight.bold),
                const SizedBox(
                  height: 5,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Alignement pour éviter les erreurs de taille
                  children: ratings.keys.map((rating) {
                    final percentage = ratings[rating]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: RatingBar(
                        stars: rating,
                        percentage: percentage,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 130, // Ajustez cette hauteur selon votre besoin
            child: VerticalDivider(
              width: 40,
            ),
          ),
          const ComponentLsHeader(
              label: "Etat des lieux",
              note: "4",
              icon: Icon(Icons.cleaning_services)),
          const SizedBox(
            //padding: EdgeInsets.only(top: 10),
            height: 130, // Ajustez cette hauteur selon votre besoin
            child: VerticalDivider(
              width: 40,
            ),
          ),
          const ComponentLsHeader(
              label: "Régularité", note: "5", icon: Icon(Icons.euro)),
          const SizedBox(
            //padding: EdgeInsets.only(top: 10),
            height: 130, // Ajustez cette hauteur selon votre besoin
            child: VerticalDivider(
              width: 40,
            ),
          ),
          const ComponentLsHeader(
              label: "Communication",
              note: "5",
              icon: Icon(Icons.chat_bubble_outline_outlined)),
          const SizedBox(
            //padding: EdgeInsets.only(top: 10),
            height: 130, // Ajustez cette hauteur selon votre besoin
            child: VerticalDivider(
              width: 40,
            ),
          ),
          const ComponentLsHeader(
              label: "Vie", note: "3", icon: Icon(Icons.group)),
        ],
      ),
    );
  }
}
