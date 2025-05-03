import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
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
        final bool hasStepper =
            post.type == "sinistres" || post.type == "incivilites";

        showModalBottomSheet(
          showDragHandle: true,
          isScrollControlled: hasStepper,
          context: context,
          builder: (context) {
            if (!hasStepper) {
              // 🎯 CAS SANS STEPPER : hauteur minimale
              return SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListTile(
                    leading: const Icon(Icons.delete),
                    title: MyTextStyle.postDesc(
                      'Supprimer',
                      SizeFont.h3.size,
                      Colors.black87,
                    ),
                    onTap: () {
                      showAlertDialog(post, context, updatePostsList);
                    },
                  ),
                ),
              );
            }

            // 📌 CAS AVEC STEPPER
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.65,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20.0),
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
                                    subtitle: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height -
                                              550,
                                      child: Stepper(
                                        currentStep:
                                            _getCurrentStep(post.statu),
                                        steps: [
                                          Step(
                                            isActive:
                                                post.statu! == "En attente",
                                            title: MyTextStyle.postDesc(
                                                "En attente",
                                                SizeFont.h3.size,
                                                Colors.black54),
                                            content: MyTextStyle.lotDesc(
                                                "Envoyer cette déclaration de sinistre a votre gestionnaire",
                                                SizeFont.para.size,
                                                FontStyle.italic),
                                          ),
                                          Step(
                                            isActive: post.statu! ==
                                                "Prise en compte",
                                            title: MyTextStyle.postDesc(
                                                "Prise en compte",
                                                SizeFont.h3.size,
                                                Colors.black54),
                                            content: const SizedBox(),
                                          ),
                                          Step(
                                            isActive: post.statu! == "Terminé",
                                            title: MyTextStyle.postDesc(
                                                "Terminé",
                                                SizeFont.h3.size,
                                                Colors.black54),
                                            content: const SizedBox(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  SafeArea(
                                    top: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: ListTile(
                                        leading: const Icon(Icons.delete),
                                        title: MyTextStyle.postDesc(
                                          'Supprimer',
                                          SizeFont.h3.size,
                                          Colors.black87,
                                        ),
                                        onTap: () {
                                          showAlertDialog(
                                              post, context, updatePostsList);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
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

int _getCurrentStep(String? statut) {
  switch (statut) {
    case "En attente":
      return 0;
    case "Prise en compte":
      return 1;
    case "Terminé":
      return 2;
    default:
      return 0;
  }
}

Future<void> _onDeletePost(Post post, Function updatePostsList) async {
  final StorageServices _storageServices = StorageServices();
  final dbService = DataBasesPostServices();
  await dbService.removePost(post.refResidence, post.id);
  await _storageServices.removeFileFromUrl(post.pathImage!);
  updatePostsList();
}

void showAlertDialog(
    Post post, BuildContext context, Function updatePostsList) {
  Widget cancelButton = TextButton(
    child: MyTextStyle.lotName("Annuler", Colors.black87, SizeFont.h3.size),
    onPressed: () {
      if (context.mounted) Navigator.pop(context);
    },
  );
  Widget continueButton = TextButton(
    child: MyTextStyle.lotName("Supprimer", Colors.black87, SizeFont.h3.size),
    onPressed: () async {
      Navigator.pop(context); // Ferme le BottomSheet
      await _onDeletePost(post, updatePostsList);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Ferme l'AlertDialog
      }
    },
  );

  AlertDialog alert = AlertDialog(
    title:
        MyTextStyle.lotName("Confirmation", Colors.black87, SizeFont.h1.size),
    content: MyTextStyle.annonceDesc(
      "Êtes-vous sûr de vouloir supprimer ${post.title} ?",
      SizeFont.h3.size,
      3,
    ),
    actions: [cancelButton, continueButton],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) => alert,
  );
}
