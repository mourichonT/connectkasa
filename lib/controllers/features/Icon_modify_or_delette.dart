import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_post_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';

Widget IconModifyOrDelette(Post post, BuildContext context) {
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 10),
    child: GestureDetector(
      onTap: () {
        // Affichage du BottomSheet
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                // Conversion du statut actuel en enum
                StatutPostList selectedStatut =
                    StatutPostList.fromString(post.statu!);

                return Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section modification du statut
                      Visibility(
                        visible: post.type == "sinistres" ||
                            post.type == "incivilites",
                        child: ListTile(
                          title: Row(
                            children: [
                              const Icon(Icons.edit),
                              const SizedBox(width: 15),
                              MyTextStyle.postDesc(
                                'Modifier le statut',
                                SizeFont.h3.size,
                                Colors.black87,
                              ),
                            ],
                          ),
                          subtitle: Wrap(
                            spacing: 8.0,
                            children: StatutPostList.values
                                .where(
                                    (statut) => statut != StatutPostList.empty)
                                .map(
                                  (statut) => FilterChip(
                                    label: Text(statut.label),
                                    selected: selectedStatut == statut,
                                    onSelected: (bool selected) {
                                      if (selected) {
                                        setState(() {
                                          selectedStatut = statut;
                                          post.statu = statut
                                              .label; // Mise à jour locale du post

                                          // Mise à jour en base de données
                                          SubmitPostController.UpdatePost(
                                            like: post.like,
                                            uid: post.user,
                                            statu: statut.label,
                                            idPost: post.id,
                                            selectedLabel: post.type,
                                            imagePath: post.pathImage,
                                            title: post.title,
                                            desc: post.description,
                                            anonymPost: post.hideUser,
                                            docRes: post.refResidence,
                                            localisation: post.location_element,
                                            etage: post.location_floor,
                                            element: post.location_details,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      // Section suppression du post
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: MyTextStyle.postDesc(
                          'Supprimer',
                          SizeFont.h3.size,
                          Colors.black87,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: const Icon(
        Icons.more_vert_outlined,
        size: 24,
        color: Colors.black,
      ),
    ),
  );
}
