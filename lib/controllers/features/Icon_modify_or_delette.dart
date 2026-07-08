import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/agency_search_flow.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/handlers/exportpdfhttp.dart';
import 'package:connect_kasa/controllers/handlers/fetch_pdfreport.dart';
import 'package:connect_kasa/controllers/handlers/send_custom_email.dart';
import 'package:connect_kasa/core/repositories/post_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_post_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_lot_repository.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/core/repositories/firestore_storage_repository.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/gerance_ref.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:flutter/material.dart';

FetchPdfreport fetchPDFreport = FetchPdfreport();

/// Résout le mail de notification d'un sinistre : mail_contact (résidence
/// non déléguée) en priorité, sinon la gérance/agence résolue (déléguée -
/// mail_contact est volontairement vidé dans ce cas côté
/// management_res_info_g.dart, pour ne pas dupliquer une donnée qui peut
/// devenir périmée).
///
/// Lit directement Firestore plutôt que lot.residenceData : ce dernier est
/// une copie chargée une fois puis mise en cache (SharedPreferences, "lot
/// préféré") qui ne se rafraîchit pas quand la résidence est modifiée
/// ailleurs (ex. management_res_info_g.dart) sans que l'utilisateur ne
/// resélectionne son lot - un simple hot restart ne suffit pas à la
/// rafraîchir.
Future<String?> _resolveContactEmail(String residenceId) async {
  final residenceSnapshot = await FirebaseFirestore.instance
      .collection("Residence")
      .doc(residenceId)
      .get();
  final residenceData = residenceSnapshot.data();
  if (residenceData == null) return null;

  final directMail = residenceData['mail_contact'] as String?;
  if (directMail != null && directMail.isNotEmpty) {
    return directMail;
  }

  final geranceRefData = residenceData['geranceRef'];
  if (geranceRefData != null) {
    final geranceRef =
        GeranceRef.fromJson(Map<String, dynamic>.from(geranceRefData));
    final flow = AgencySearchFlow(serviceType: 'serviceSyndic');
    final agency = await flow.resolve(geranceRef);
    final agencyMail = agency?.syndic?.mail;
    if (agencyMail != null && agencyMail.isNotEmpty) {
      return agencyMail;
    }
  }

  final syndicAgencyData = residenceData['syndicAgency'];
  if (syndicAgencyData != null) {
    final customMail =
        (syndicAgencyData as Map)['syndic']?['mail'] as String?;
    if (customMail != null && customMail.isNotEmpty) {
      return customMail;
    }
  }

  return null;
}

/// Rôle du déclarant (post.user) dans son lot de cette résidence :
/// "Propriétaire" ou "Locataire". Retrouve son lot via User/{uid}/lots
/// plutôt que d'utiliser le lot du CS member consultant le post - ce n'est
/// pas forcément le même (le déclarant peut être dans un lot différent).
Future<String?> _resolveDeclarantStatus(Post post) async {
  final lots = await FirestoreLotRepository()
      .getLotByIdUser(post.user)
      .then((result) => result.when(success: (v) => v, failure: (_) => <Lot>[]));

  Lot? declarantLot;
  for (final l in lots) {
    if (l.residenceId == post.refResidence) {
      declarantLot = l;
      break;
    }
  }
  if (declarantLot == null) return null;

  if (declarantLot.idProprietaire?.contains(post.user) ?? false) {
    return 'Propriétaire';
  }
  if (declarantLot.idLocataire?.contains(post.user) ?? false) {
    return 'Locataire';
  }
  return null;
}

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
                        final contactEmail =
                            await _resolveContactEmail(post.refResidence);
                        if (contactEmail != null && contactEmail.isNotEmpty) {
                          final declarantStatus =
                              await _resolveDeclarantStatus(post);
                          await sendCustomEmail(
                            lot: lot!,
                            post: post,
                            email: contactEmail,
                            subjectMail: 'Nouveau signalement ConnectKasa',
                            declarantStatus: declarantStatus,
                          );
                        }

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
  final storageServices = FirestoreStorageRepository();
  final IPostRepository dbService = FirestorePostRepository();

  await dbService
      .removePost(post.refResidence, post.id)
      .then((result) => result.when(
          success: (_) {}, failure: (error) => throw error));
  if (post.pathImage != null) {
    await storageServices.removeFileFromUrl(post.pathImage!);
  }

  updatePostsList();
}

void showAlertDialog(
    Post post, BuildContext context, Function updatePostsList) {
  // dialogContext (fourni par le builder de showDialog) sert à fermer la
  // seule AlertDialog ; context (celui du BottomSheet, capturé avant
  // l'appel) sert à fermer le BottomSheet séparément. Avant ce correctif,
  // les deux boutons utilisaient le même `context` capturé avant
  // showDialog pour les deux Navigator.pop, ce qui fermait les mauvaises
  // couches dans le mauvais ordre - jusqu'à parfois popper la page
  // elle-même après la suppression, provoquant un
  // "setState() called after dispose()".
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: MyTextStyle.lotName(
            "Confirmation", Colors.black87, SizeFont.h1.size),
        content: MyTextStyle.annonceDesc(
          "Êtes-vous sûr de vouloir supprimer ${post.title} ?",
          SizeFont.h3.size,
          3,
        ),
        actions: [
          TextButton(
            child: MyTextStyle.lotName(
                "Annuler", Colors.black87, SizeFont.h3.size),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          TextButton(
            child: MyTextStyle.lotName(
                "Supprimer", Colors.black87, SizeFont.h3.size),
            onPressed: () async {
              Navigator.pop(dialogContext); // Ferme l'AlertDialog
              Navigator.pop(context); // Ferme le BottomSheet
              await _onDeletePost(post, updatePostsList);
            },
          ),
        ],
      );
    },
  );
}
