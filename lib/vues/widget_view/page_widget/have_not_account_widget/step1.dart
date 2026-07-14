import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class Step1 extends StatefulWidget {
  final Function(Residence) recupererInformationsStep1;
  final VoidCallback onNoResidence;
  final int currentPage;
  final PageController progressController;
  // Masqué dans le parcours de rattachement d'un utilisateur déjà approuvé
  // (AttachExistingLotPage, my_nav_bar.dart "no lot") : cet utilisateur
  // cherche précisément à rattacher une résidence, "je n'en ai pas encore"
  // n'a pas de sens dans ce contexte.
  final bool showNoResidenceOption;

  const Step1({
    super.key,
    required this.recupererInformationsStep1,
    required this.onNoResidence,
    required this.currentPage,
    required this.progressController,
    this.showNoResidenceOption = true,
  });

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  late double width;
  final TextEditingController _addressController = TextEditingController();
  // List<String> suggestions = [];
  Residence? selectedResidence;
  late List<Residence> residencesTrouvees;
  bool visible = false;
  bool noResidence = false;

  Residence? getResidence() {
    if (selectedResidence != null) {
      return selectedResidence;
    } else {
      // handle the case where selectedResidence is null
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MyTextStyle.lotName(
                """à présent recherchons votre résidence """, Colors.black54),
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: FutureBuilder<List<String>>(
                    future: saisieAsyncFunction(_addressController.text),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: AppLoader());
                      } else {
                        return AutoCompleteTextField<String>(
                          controller: _addressController,
                          itemSubmitted: (item) {
                            setState(() {
                              _addressController.text = item;
                              visible = true;
                              selectedResidence = residencesTrouvees.firstWhere(
                                  (residence) =>
                                      "${residence.name} - ${residence.street} ${residence.zipCode} ${residence.city}" ==
                                      item);
                            });
                          },
                          key: GlobalKey<AutoCompleteTextFieldState<String>>(),
                          itemBuilder: (context, item) {
                            return ListTile(
                              title: Text(item),
                            );
                          },
                          itemSorter: (a, b) => a.compareTo(b),
                          itemFilter: (item, query) =>
                              item.toLowerCase().contains(query.toLowerCase()),
                          suggestions: snapshot.data ?? [],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Nom de résidence / Adresse / Ville',
                            hintStyle:
                                TextStyle(color: Colors.black45, fontSize: 15),
                          ),
                          submitOnSuggestionTap: true,
                          clearOnSubmit: false,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (widget.showNoResidenceOption) ...[
            const SizedBox(
              height: 20,
            ),
            CheckboxListTile(
              value: noResidence,
              onChanged: (value) {
                setState(() {
                  noResidence = value ?? false;
                });
              },
              title: MyTextStyle.postDesc(
                "Je n'ai pas encore de résidence",
                SizeFont.h3.size,
                Colors.black54,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          const SizedBox(
            height: 130,
          ),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: noResidence || getResidence().toString().isNotEmpty,
        child: BottomAppBar(
            surfaceTintColor: Colors.white,
            padding: const EdgeInsets.all(2),
            height: 70,
            child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  TextButton(
                    onPressed: () {
                      if (noResidence) {
                        widget.onNoResidence();
                        return;
                      }

                      Residence residence = getResidence()!;

                      widget.recupererInformationsStep1(residence);
                      // Action à effectuer lorsque le bouton "Suivant" est pressé
                      if (widget.currentPage < 5) {
                        widget.progressController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: const Text(
                      'Suivant',
                    ),
                  ),
                ])),
      ),
    );
  }

  Future<List<String>> saisieAsyncFunction(String saisie) async {
    // Appel de la fonction asynchrone pour récupérer les résidences trouvées

    residencesTrouvees = await FirestoreResidenceRepository()
        .rechercheFirestore(saisie)
        .then((result) =>
            result.when(success: (v) => v, failure: (error) => throw error));

    // Maintenant que la fonction asynchrone est terminée, vous pouvez utiliser les résidences trouvées
    // Convertir les objets Residence en noms de résidence
    List<String> nomsResidences = residencesTrouvees
        .map((residence) =>
            "${residence.name} - ${residence.street} ${residence.zipCode} ${residence.city}")
        .toList();

    return nomsResidences;
  }
}
