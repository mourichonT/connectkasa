import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/handlers/exportpdfhttp.dart';
import 'package:connect_kasa/controllers/handlers/fetch_pdfreport.dart';
import 'package:connect_kasa/controllers/handlers/send_custom_email.dart';
import 'package:connect_kasa/controllers/services/databases_mail_services.dart';
import 'package:connect_kasa/controllers/services/databases_post_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:flutter/material.dart';

FetchPdfreport fetchPDFreport = FetchPdfreport();
final DatabasesMailServices _mailChatServices = DatabasesMailServices();
Widget IconModifyOrDelette(
    Post post, Lot lot, BuildContext context, Function updatePostsList) {
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

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.65,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    int currentStep = _getCurrentStep(post.statu);

                    Future<void> handleContinue() async {
                      if (currentStep == 0) {
                        await SubmitPostController.UpdatePost(
                          like: post.like,
                          uid: post.user,
                          statu: "Prise en compte",
                          timeStamp: post.timeStamp,
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
                          declaredDate: Timestamp.now(),
                        );
                        await sendCustomEmail(
                          lot: lot!,
                          post: post,
                          email: 'mourichon.thibault@gmail.com',
                          subjectMail: 'Nouveau signalement ConnectKasa',
                        );

                        setState(() {
                          currentStep = 1;
                          post.statu = "Prise en compte";
                        });
                      } else if (currentStep == 1) {
                        await SubmitPostController.UpdatePost(
                          like: post.like,
                          uid: post.user,
                          statu: "Terminé",
                          idPost: post.id,
                          selectedLabel: post.type,
                          imagePath: post.pathImage,
                          title: post.title,
                          timeStamp: post.timeStamp,
                          desc: post.description,
                          anonymPost: post.hideUser,
                          docRes: post.refResidence,
                          localisation: post.location_element,
                          etage: post.location_floor,
                          element: post.location_details,
                        );
                        setState(() {
                          currentStep = 2;
                          post.statu = "Terminé";
                        });
                      }
                    }

                    Future<void> handleCanceled() async {
                      if (currentStep == 1) {
                        await SubmitPostController.UpdatePost(
                          like: post.like,
                          uid: post.user,
                          statu: "En attente",
                          idPost: post.id,
                          selectedLabel: post.type,
                          imagePath: post.pathImage,
                          title: post.title,
                          timeStamp: post.timeStamp,
                          desc: post.description,
                          anonymPost: post.hideUser,
                          docRes: post.refResidence,
                          localisation: post.location_element,
                          etage: post.location_floor,
                          element: post.location_details,
                        );

                        setState(() {
                          currentStep = 0;
                          post.statu = "En attente";
                        });
                      } else if (currentStep == 2) {
                        await SubmitPostController.UpdatePost(
                          like: post.like,
                          uid: post.user,
                          statu: "Prise en compte",
                          timeStamp: post.timeStamp,
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
                          declaredDate: Timestamp.now(),
                        );
                        setState(() {
                          currentStep = 0;
                          post.statu = "Prise en compte";
                        });
                      }
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
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
                                  subtitle: Stepper(
                                    controlsBuilder: (BuildContext context,
                                        ControlsDetails details) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Row(
                                          children: <Widget>[
                                            Visibility(
                                              visible: currentStep != 2,
                                              child: ElevatedButton(
                                                onPressed:
                                                    details.onStepContinue,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: MyTextStyle.postDesc(
                                                    "Suivant",
                                                    SizeFont.para.size,
                                                    Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Visibility(
                                              visible: currentStep != 1 &&
                                                  currentStep != 0,
                                              child: TextButton(
                                                onPressed: details.onStepCancel,
                                                child: MyTextStyle.postDesc(
                                                  "Retour",
                                                  SizeFont.para.size,
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onStepTapped: (newIndex) {
                                      setState(() {
                                        currentStep = newIndex;
                                      });
                                    },
                                    currentStep: currentStep,
                                    onStepContinue: handleContinue,
                                    onStepCancel: handleCanceled,
                                    steps: [
                                      Step(
                                        isActive: currentStep == 0,
                                        title: MyTextStyle.postDesc(
                                          "En attente",
                                          SizeFont.h3.size,
                                          currentStep == 0
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.black54,
                                        ),
                                        content: MyTextStyle.lotDesc(
                                          "Envoyez cette déclaration de sinistre à votre gestionnaire.",
                                          SizeFont.para.size,
                                          FontStyle.italic,
                                        ),
                                      ),
                                      Step(
                                        isActive: currentStep == 1,
                                        title: MyTextStyle.postDesc(
                                            "Prise en compte",
                                            SizeFont.h3.size,
                                            currentStep == 1
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.black54),
                                        content: MyTextStyle.lotDesc(
                                          "Votre gestionnaire a reçu votre déclaration. Le prestataire a réalisé les travaux liés au sinistre.",
                                          SizeFont.para.size,
                                          FontStyle.italic,
                                        ),
                                      ),
                                      Step(
                                        isActive: currentStep == 2,
                                        title: MyTextStyle.postDesc(
                                            "Terminé",
                                            SizeFont.h3.size,
                                            currentStep == 2
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.black54),
                                        content: MyTextStyle.lotDesc(
                                          "La déclaration est clôturée.",
                                          SizeFont.para.size,
                                          FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
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
  final storageServices = StorageServices();
  final dbService = DataBasesPostServices();

  await dbService.removePost(post.refResidence, post.id);
  if (post.pathImage != null) {
    await storageServices.removeFileFromUrl(post.pathImage!);
  }

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
