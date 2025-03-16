import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_post_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:flutter/material.dart';

Widget IconModifyOrDelette(
    Post post, BuildContext context, Function updatePostsList) {
  return Container(
    padding: const EdgeInsets.only(left: 20, right: 10),
    child: GestureDetector(
      onTap: () {
        // Affichage du BottomSheet
        showModalBottomSheet(
          showDragHandle: true,
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                // Conversion du statut actuel en enum
                StatutPostList selectedStatut =
                    StatutPostList.fromString(post.statu!);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Section modification du statut
                    Visibility(
                      visible: post.type == "sinistres" ||
                          post.type == "incivilites",
                      child: ListTile(
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
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
                        ),
                        subtitle: Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 8.0,
                                children: StatutPostList.values
                                    .where((statut) =>
                                        statut != StatutPostList.empty)
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
                                                localisation:
                                                    post.location_element,
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
                              SizedBox(
                                height: 10,
                              ),
                              const Divider(),
                            ],
                          ),
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
                        // Fermer le BottomSheet avant d'afficher l'AlertDialog
                        //Navigator.pop(context); // Ferme le BottomSheet
                        showAlertDialog(post, context, updatePostsList);
                      },
                    ),

                    SizedBox(
                      height: 30,
                    )
                  ],
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

Future<void> _onDeletePost(Post post, Function updatePostsList) async {
  final StorageServices _storageServices = StorageServices();
  DataBasesPostServices dbService = DataBasesPostServices();
  await dbService.removePost(post.refResidence, post.id);
  await _storageServices.removeFileFromUrl(post.pathImage!);
  updatePostsList();
}

showAlertDialog(
  Post post,
  BuildContext context,
  Function updatePostsList, // Ajouter le paramètre ici
) async {
  Widget cancelButton = TextButton(
    child: MyTextStyle.lotName("Annuler ", Colors.black87, SizeFont.h3.size),
    onPressed: () {
      if (context.mounted) {
        Navigator.pop(context); // Ferme l'alert
      }
    },
  );
  Widget continueButton = TextButton(
    child: MyTextStyle.lotName("Supprimer ", Colors.black87, SizeFont.h3.size),
    onPressed: () async {
      // Fermer d'abord le BottomSheet
      Navigator.pop(context); // Ferme le BottomSheet

      // Effectuer la suppression
      await _onDeletePost(
          post, updatePostsList); // Passer la fonction updatePostsList

      // Fermer l'AlertDialog après la suppression
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Ferme l'AlertDialog
      }
    },
  );

  AlertDialog alert = AlertDialog(
    title:
        MyTextStyle.lotName("Confirmation ", Colors.black87, SizeFont.h1.size),
    content: MyTextStyle.annonceDesc(
        "Etes-vous sûr de vouloir supprimer ${post.title} ",
        SizeFont.h3.size,
        3),
    actions: [
      cancelButton,
      continueButton,
    ],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
