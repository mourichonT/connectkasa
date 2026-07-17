import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/agency_search_flow.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/controllers/handlers/fetch_pdfreport.dart';
import 'package:konodal/controllers/handlers/send_custom_email.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/core/repositories/firestore_storage_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/post.dart';
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
      .collection("residences")
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
/// "Propriétaire" ou "Locataire". Retrouve son lot via users/{uid}/lots
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

Widget iconModifyOrDelette(
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
                    int currentStep = _getCurrentStep(post.statut);

                    void showUpdateError(Object e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content:
                              Text('Erreur lors de la mise à jour : $e'),
                        ),
                      );
                    }

                    Future<void> handleContinue() async {
                      try {
                        if (currentStep == 0) {
                          // Non envoyé -> Transmis : c'est ce déclencheur
                          // précis qui notifie la gérance par mail (une seule
                          // fois, au moment exact de l'envoi).
                          await SubmitPostController.updatePost(
                            like: post.like,
                            uid: post.user,
                            statut: "Transmis",
                            timeStamp: post.creationDate,
                            idPost: post.id,
                            selectedLabel: post.type,
                            imagePath: post.pathImage,
                            isVideo: post.isVideo,
                            title: post.title,
                            desc: post.description,
                            anonymPost: post.hideUser,
                            docRes: post.refResidence,
                            localisation: post.locationElement,
                            etage: post.locationFloor,
                            element: post.locationDetails,
                            declaredDate: Timestamp.now(),
                          );
                          final contactEmail =
                              await _resolveContactEmail(post.refResidence);
                          if (contactEmail != null &&
                              contactEmail.isNotEmpty) {
                            final declarantStatus =
                                await _resolveDeclarantStatus(post);
                            await sendCustomEmail(
                              lot: lot,
                              post: post,
                              email: contactEmail,
                              subjectMail: 'Nouveau signalement KONODAL',
                              declarantStatus: declarantStatus,
                            );
                          }

                          setState(() {
                            currentStep = 1;
                            post.statut = "Transmis";
                          });
                        } else if (currentStep == 1) {
                          // Transmis -> En cours
                          await SubmitPostController.updatePost(
                            like: post.like,
                            uid: post.user,
                            statut: "En cours",
                            idPost: post.id,
                            selectedLabel: post.type,
                            imagePath: post.pathImage,
                            isVideo: post.isVideo,
                            title: post.title,
                            timeStamp: post.creationDate,
                            desc: post.description,
                            anonymPost: post.hideUser,
                            docRes: post.refResidence,
                            localisation: post.locationElement,
                            etage: post.locationFloor,
                            element: post.locationDetails,
                          );
                          setState(() {
                            currentStep = 2;
                            post.statut = "En cours";
                          });
                        } else if (currentStep == 2) {
                          // En cours -> Terminé
                          await SubmitPostController.updatePost(
                            like: post.like,
                            uid: post.user,
                            statut: "Terminé",
                            idPost: post.id,
                            selectedLabel: post.type,
                            imagePath: post.pathImage,
                            isVideo: post.isVideo,
                            title: post.title,
                            timeStamp: post.creationDate,
                            desc: post.description,
                            anonymPost: post.hideUser,
                            docRes: post.refResidence,
                            localisation: post.locationElement,
                            etage: post.locationFloor,
                            element: post.locationDetails,
                          );
                          // dateClosed : pas modélisé sur Post (cf.
                          // updatePostFields) pour ne jamais risquer qu'un
                          // futur appel à updatePost() l'efface - écrit ici en
                          // ciblé, une seule fois, au moment exact de la
                          // clôture.
                          await FirestorePostRepository().updatePostFields(
                            post.refResidence,
                            post.id,
                            {'dates.closedDate': Timestamp.now()},
                          );
                          setState(() {
                            currentStep = 3;
                            post.statut = "Terminé";
                          });
                        }
                      } catch (e) {
                        showUpdateError(e);
                      }
                    }

                    Future<void> handleCanceled() async {
                      try {
                        // Réouverture depuis Terminé uniquement (même
                        // restriction que l'ancien workflow à 3 étapes : le
                        // bouton "Retour" n'est visible que sur la dernière
                        // étape, cf. Visibility ci-dessous).
                        if (currentStep == 3) {
                          await SubmitPostController.updatePost(
                            like: post.like,
                            uid: post.user,
                            statut: "En cours",
                            timeStamp: post.creationDate,
                            idPost: post.id,
                            selectedLabel: post.type,
                            imagePath: post.pathImage,
                            isVideo: post.isVideo,
                            title: post.title,
                            desc: post.description,
                            anonymPost: post.hideUser,
                            docRes: post.refResidence,
                            localisation: post.locationElement,
                            etage: post.locationFloor,
                            element: post.locationDetails,
                          );
                          // La réouverture efface dateClosed (fixé lors du
                          // passage en Terminé) - il sera réécrit si le
                          // ticket repasse en Terminé plus tard.
                          await FirestorePostRepository().updatePostFields(
                            post.refResidence,
                            post.id,
                            {'dates.closedDate': FieldValue.delete()},
                          );
                          setState(() {
                            currentStep = 2;
                            post.statut = "En cours";
                          });
                        }
                      } catch (e) {
                        showUpdateError(e);
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
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
                                        // Remonté ici (au lieu d'en bas de la
                                        // liste des 4 étapes du Stepper,
                                        // entièrement dépliées) : sinon
                                        // "Supprimer" se retrouve hors de la
                                        // zone visible du bottom sheet
                                        // (initialChildSize 0.6), sans scroll
                                        // évident pour l'atteindre.
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          tooltip: 'Supprimer',
                                          onPressed: () => showAlertDialog(
                                              post, context, updatePostsList),
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
                                              visible: currentStep != 3,
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
                                              visible: currentStep == 3,
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
                                          "Non envoyé",
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
                                            "Transmis",
                                            SizeFont.h3.size,
                                            currentStep == 1
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.black54),
                                        content: MyTextStyle.lotDesc(
                                          "Votre gestionnaire a reçu votre déclaration.",
                                          SizeFont.para.size,
                                          FontStyle.italic,
                                        ),
                                      ),
                                      Step(
                                        isActive: currentStep == 2,
                                        title: MyTextStyle.postDesc(
                                            "En cours",
                                            SizeFont.h3.size,
                                            currentStep == 2
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.black54),
                                        content: MyTextStyle.lotDesc(
                                          "Le prestataire réalise les travaux liés au sinistre.",
                                          SizeFont.para.size,
                                          FontStyle.italic,
                                        ),
                                      ),
                                      Step(
                                        isActive: currentStep == 3,
                                        title: MyTextStyle.postDesc(
                                            "Terminé",
                                            SizeFont.h3.size,
                                            currentStep == 3
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
                                const SafeArea(
                                  top: false,
                                  child: SizedBox(height: 20),
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
    case "Non envoyé":
      return 0;
    case "Transmis":
      return 1;
    case "En cours":
      return 2;
    case "Terminé":
      return 3;
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
              try {
                await _onDeletePost(post, updatePostsList);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Erreur lors de la suppression : $e'),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}
