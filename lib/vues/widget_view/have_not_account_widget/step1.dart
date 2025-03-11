import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:flutter/material.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';

class Step1 extends StatefulWidget {
  final Function(Residence) recupererInformationsStep1;
  final int currentPage;
  final PageController progressController;

  const Step1({
    super.key,
    required this.recupererInformationsStep1,
    required this.currentPage,
    required this.progressController,
  });

  @override
  _Step1State createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  late double width;
  final TextEditingController _addressController = TextEditingController();
  // List<String> suggestions = [];
  Residence? selectedResidence;
  late List<Residence> residencesTrouvees;
  bool visible = false;

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FutureBuilder<List<String>>(
              future: saisieAsyncFunction(_addressController.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Indicateur de chargement
                } else {
                  return AutoCompleteTextField<String>(
                      controller: _addressController,
                      itemSubmitted: (item) {
                        setState(() {
                          _addressController.text = item;
                          visible = true;
                          selectedResidence = residencesTrouvees.firstWhere(
                              (residence) =>
                                  "${residence.name} - ${residence.numero} ${residence.street} ${residence.zipCode} ${residence.city}" ==
                                  item);
                        });
                      },
                      key: GlobalKey<AutoCompleteTextFieldState<String>>(),
                      itemBuilder: (context, item) {
                        return ListTile(
                          title: Text(item),
                        );
                      },
                      itemSorter: (a, b) {
                        return a.compareTo(b);
                      },
                      itemFilter: (item, query) {
                        return item.toLowerCase().contains(query.toLowerCase());
                      },
                      suggestions: snapshot.data ??
                          [], // Utilise les données de la future
                      decoration: const InputDecoration(
                        hintText: 'Nom de résidence / Adresse / Ville',
                        hintStyle:
                            TextStyle(color: Colors.black45, fontSize: 15),
                      ),
                      submitOnSuggestionTap: true,
                      clearOnSubmit: false);
                }
              },
            ),
          ),
          const SizedBox(
            height: 150,
          ),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: getResidence().toString().isNotEmpty,
        child: BottomAppBar(
            surfaceTintColor: Colors.white,
            padding: const EdgeInsets.all(2),
            height: 70,
            child: Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  TextButton(
                    onPressed: () {
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
                ]))),
      ),
    );
  }

  Future<List<String>> saisieAsyncFunction(String saisie) async {
    // Appel de la fonction asynchrone pour récupérer les résidences trouvées

    residencesTrouvees =
        await DataBasesResidenceServices().rechercheFirestore(saisie);

    // Maintenant que la fonction asynchrone est terminée, vous pouvez utiliser les résidences trouvées
    // Convertir les objets Residence en noms de résidence
    List<String> nomsResidences = residencesTrouvees
        .map((residence) =>
            "${residence.name} - ${residence.numero} ${residence.street} ${residence.zipCode} ${residence.city}")
        .toList();

    return nomsResidences;
  }
}
