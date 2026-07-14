import 'dart:async';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/handlers/send_demande_email.dart';
import 'package:konodal/core/providers/demande_providers.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:konodal/vues/widget_view/components/my_text_fied.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LookUpUser {
  // Même mécanisme d'autocomplétion des résidences référencées dans l'app
  // qu'à l'inscription (cf. Step1.saisieAsyncFunction) : recherche par
  // nom/adresse/ville via FirestoreResidenceRepository.rechercheFirestore.
  static Future<List<Residence>> _saisieResidences(String saisie) async {
    return FirestoreResidenceRepository()
        .rechercheFirestore(saisie)
        .then((result) =>
            result.when(success: (v) => v, failure: (error) => throw error));
  }

  // Bâtiments/lots référencés dans la résidence choisie (cf.
  // Step3.getBatimentLot/getSpecificLot à l'inscription) : simple aide au
  // ciblage pour le bailleur, pas de rattachement réel à un Lot existant.
  static Future<List<String>> _getBatiments(String residenceId) async {
    final lots = await FirestoreLotRepository()
        .getLotByResidence(residenceId)
        .then((result) => result.when(success: (v) => v, failure: (_) => <Lot>[]));
    return lots.map((l) => l.batiment).whereType<String>().toSet().toList();
  }

  static Future<List<String>> _getLots(String residenceId,
      [String? batiment]) async {
    final lots = await FirestoreLotRepository()
        .getLotByResidence(residenceId)
        .then((result) => result.when(success: (v) => v, failure: (_) => <Lot>[]));
    return lots
        .where((l) => batiment == null || batiment.isEmpty || l.batiment == batiment)
        .map((l) => l.lot)
        .whereType<String>()
        .toSet()
        .toList();
  }

  static Future<String?> searchUserForm(
      BuildContext context, DemandeLoc demande) {
    final TextEditingController emailController = TextEditingController();
    // Adresse : informative uniquement (aide le bailleur qui gère plusieurs
    // biens à identifier le lot visé) - pas liée à un Address existant.
    final TextEditingController lotAddressController = TextEditingController();

    Timer? debounce;
    List<Residence> suggestions = [];
    Residence? selectedResidence;
    String batChoice = "";
    String lotChoice = "";
    Future<List<String>> batimentsFuture = Future.value([]);
    Future<List<String>> lotsFuture = Future.value([]);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          // Largeur explicite plutôt qu'un LayoutBuilder : AlertDialog
          // dimensionne son content via IntrinsicWidth, qui ne supporte pas
          // les requêtes de dimensions intrinsèques d'un LayoutBuilder
          // ("LayoutBuilder does not support returning intrinsic dimensions")
          // - provoquait un crash au rendu empêchant la modale de s'ouvrir.
          // 80 = insetPadding horizontal par défaut d'AlertDialog (40 de
          // chaque côté).
          final dialogWidth = MediaQuery.of(context).size.width - 80;
          final dropdownWidth = dialogWidth - 10;
          return AlertDialog(
            title: MyTextStyle.lotName(
                "Destinataire", Colors.black87, SizeFont.h2.size),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Mail ou N° utilisateur',
                        hintStyle:
                            TextStyle(color: Colors.black45, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: lotAddressController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Adresse du lot souhaité',
                        hintStyle:
                            TextStyle(color: Colors.black45, fontSize: 15),
                      ),
                      onChanged: (query) {
                        selectedResidence = null;
                        debounce?.cancel();
                        debounce =
                            Timer(const Duration(milliseconds: 350), () async {
                          final results = await _saisieResidences(query);
                          setState(() => suggestions = results);
                        });
                      },
                    ),
                  ),
                  // Suggestions affichées en ligne (pas en overlay) : un
                  // AutoCompleteTextField (Overlay.of(context)) ne s'affichait
                  // pas correctement une fois imbriqué dans un AlertDialog,
                  // rendant la sélection d'une résidence impossible - même
                  // technique que AddressSearchField (API BAN).
                  if (suggestions.isNotEmpty && selectedResidence == null)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: const Color(0xFFF5F6F9), width: 2),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: suggestions.map((r) {
                          final label =
                              "${r.name} - ${r.street} ${r.zipCode} ${r.city}";
                          return ListTile(
                            dense: true,
                            title: Text(label),
                            onTap: () {
                              setState(() {
                                lotAddressController.text = label;
                                selectedResidence = r;
                                suggestions = [];
                                batChoice = "";
                                lotChoice = "";
                                batimentsFuture = _getBatiments(r.id);
                                lotsFuture = _getLots(r.id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  if (selectedResidence != null) ...[
                    const SizedBox(height: 10),
                    FutureBuilder<List<String>>(
                      future: batimentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: AppLoader());
                        }
                        final batiments = snapshot.data ?? [];
                        if (batiments.isEmpty) return const SizedBox.shrink();
                        return MyDropDownMenu(
                          dropdownWidth,
                          "Bâtiment (optionnel)",
                          batChoice.isEmpty ? "Bâtiment (optionnel)" : batChoice,
                          false,
                          items: batiments,
                          onValueChanged: (value) {
                            setState(() {
                              batChoice = value;
                              lotChoice = "";
                              lotsFuture =
                                  _getLots(selectedResidence!.id, value);
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<String>>(
                      future: lotsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: AppLoader());
                        }
                        final lotsDispo = snapshot.data ?? [];
                        if (lotsDispo.isEmpty) return const SizedBox.shrink();
                        return MyDropDownMenu(
                          dropdownWidth,
                          "Numéro de lot (optionnel)",
                          lotChoice.isEmpty
                              ? "Numéro de lot (optionnel)"
                              : lotChoice,
                          false,
                          items: lotsDispo,
                          onValueChanged: (value) {
                            setState(() {
                              lotChoice = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
              ),
            ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // L'utilisateur annule
              },
              child: MyTextStyle.lotName(
                  "Annuler", Colors.black54, SizeFont.h3.size,
                  FontWeight.normal),
            ),
            TextButton(
              onPressed: () async {
                String input = emailController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Veuillez entrer une adresse email ou un N° utilisateur')),
                  );
                  return; // Ne pas fermer le dialog
                }

                // Recherche utilisateur
                User? user = await FirestoreUserRepository()
                    .getUserWithEmailOrRefApp(input, input)
                    .then((result) => result.when(
                        success: (v) => v, failure: (_) => null));

                if (user != null) {
                  final demandeWithLot = DemandeLoc(
                    timestamp: demande.timestamp,
                    tenantId: demande.tenantId,
                    garantId: demande.garantId,
                    lotAddress: lotAddressController.text.trim().isEmpty
                        ? null
                        : lotAddressController.text.trim(),
                    lotNumero: lotChoice.isEmpty
                        ? null
                        : (batChoice.isEmpty
                            ? lotChoice
                            : "$batChoice - $lotChoice"),
                  );

                  // L'utilisateur existe -> partage du fichier
                  final result = await FirestoreUserRepository()
                      .shareFile(demandeWithLot, user.uid);
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {
                      Navigator.of(context).pop(input); // Fermer avec succès
                      if (demande.tenantId != null) {
                        sendDemandeEmail(
                          tenantUid: demande.tenantId!,
                          landlordEmail: user.email,
                          lotAddress: demandeWithLot.lotAddress,
                          lotNumero: demandeWithLot.lotNumero,
                        );
                        // Sans ça, "Mes demandes en cours" (FutureProvider,
                        // pas autoDispose) garde la liste mise en cache lors
                        // d'une précédente visite et n'affiche la nouvelle
                        // demande qu'après un redémarrage complet de l'app.
                        ProviderScope.containerOf(context, listen: false)
                            .invalidate(
                                sentDemandesProvider(demande.tenantId!));
                      }
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: MyTextStyle.lotName("Dossier envoyé",
                              Theme.of(context).primaryColor, SizeFont.h1.size),
                          content: MyTextStyle.postDesc(
                            "Votre dossier a été soumis pour examen, un retour "
                            "vous sera fait après étude des pièces envoyées.",
                            SizeFont.h3.size,
                            Colors.black54,
                            fontweight: FontWeight.normal,
                            textAlign: TextAlign.justify,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: MyTextStyle.lotName(
                                  "OK", Colors.black87, SizeFont.h3.size,
                                  FontWeight.normal),
                            )
                          ],
                        ),
                      );
                    },
                    failure: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'envoi : $error'),
                        ),
                      );
                    },
                  );
                } else {
                  // Aucun utilisateur trouvé
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: MyTextStyle.lotName(
                          "Erreur", Colors.red[800]!, SizeFont.h2.size),
                      content: MyTextStyle.annonceDesc(
                          "Aucun utilisateur trouvé avec ces informations.",
                          SizeFont.h3.size,
                          3),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: MyTextStyle.lotName(
                              "OK", Colors.black87, SizeFont.h3.size,
                              FontWeight.normal),
                        )
                      ],
                    ),
                  );
                }
              },
              child: MyTextStyle.lotName(
                  "Valider", Colors.black87, SizeFont.h3.size,
                  FontWeight.normal),
            ),
          ],
        );
        });
      },
    );
  }

  static Future<String?> searchNewCSMembreForm(
    BuildContext context,
    String residenceId,
    void Function(User newUser) onUserAdded,
  ) {
    final TextEditingController emailController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Ajouter un membre", Colors.black87, SizeFont.h2.size),
          content: MyTextField(
              hintText: "Mail ou N° utilisateur",
              osbcureText: false,
              padding: 0,
              autofocus: false,
              controller: emailController),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // L'utilisateur annule
              },
              child: MyTextStyle.lotName(
                  "Annuler", Colors.black54, SizeFont.h3.size,
                  FontWeight.normal),
            ),
            TextButton(
              onPressed: () async {
                String input = emailController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Veuillez entrer une adresse email ou un N° utilisateur')),
                  );
                  return; // Ne pas fermer le dialog
                }

                // Recherche utilisateur
                User? user = await FirestoreUserRepository()
                    .getUserWithEmailOrRefApp(input, input)
                    .then((result) => result.when(
                        success: (v) => v, failure: (_) => null));

                if (user != null) {
                  // L'utilisateur existe -> ajout au conseil syndical
                  final result = await FirestoreResidenceRepository()
                      .addCsMember(residenceId, user.uid);
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {
                      onUserAdded(user);
                      Navigator.of(context).pop(input); // Fermer avec succès
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: MyTextStyle.lotName('Ajouté!',
                              Theme.of(context).primaryColor,
                              SizeFont.h1.size),
                          content: MyTextStyle.postDesc(
                            '${user.name} ${user.surname} a été ajouté avec succès !',
                            SizeFont.h3.size,
                            Colors.black54,
                            fontweight: FontWeight.normal,
                            textAlign: TextAlign.justify,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: MyTextStyle.lotName(
                                  "OK", Colors.black87, SizeFont.h3.size,
                                  FontWeight.normal),
                            )
                          ],
                        ),
                      );
                    },
                    failure: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'ajout : $error'),
                        ),
                      );
                    },
                  );
                } else {
                  // Aucun utilisateur trouvé
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: MyTextStyle.lotName(
                          "Erreur", Colors.red[800]!, SizeFont.h2.size),
                      content: MyTextStyle.annonceDesc(
                          "Aucun utilisateur trouvé avec ces informations.",
                          SizeFont.h3.size,
                          3),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: MyTextStyle.lotName(
                              "OK", Colors.black87, SizeFont.h3.size,
                              FontWeight.normal),
                        )
                      ],
                    ),
                  );
                }
              },
              child: MyTextStyle.lotName(
                  "Valider", Colors.black87, SizeFont.h3.size,
                  FontWeight.normal),
            ),
          ],
        );
      },
    );
  }
}
