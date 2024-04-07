import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:flutter/material.dart';

class Step3 extends StatefulWidget {
  final Residence residence;
  final String typeResident;
  final Function(String, String, String, String) recupererInformationsStep3;
  final int currentPage;
  final PageController progressController;

  const Step3({
    Key? key,
    required this.typeResident,
    required this.residence,
    required this.recupererInformationsStep3,
    required this.currentPage,
    required this.progressController,
  }) : super(key: key);

  @override
  _Step3State createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  bool visible = false;
  late List<Lot?> lotsTrouves;
  late String expressionTypeChoice;
  String typeChoice = "";
  String? batChoice = "";
  String? lotChoice = "";
  String? refLot = "";

  String getTypeChoice() {
    return typeChoice;
  }

  String getBatiment() {
    return batChoice!;
  }

  String getNumLot() {
    return lotChoice!;
  }

  Future<String?> getRefLot() async {
    refLot = await getlot(widget.residence.id, batChoice!, lotChoice!);
    return refLot;
  }

  @override
  void initState() {
    super.initState();
    expressionTypeChoice =
        widget.typeResident == "Locataire" ? "loué" : "acheté";
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MyTextStyle.lotName(
                "Selectionnez le type de bien que vous avez $expressionTypeChoice",
                Colors.black54),
          ),
          const SizedBox(
            height: 30,
          ),
          FutureBuilder<List<String>>(
            future: getTypeLot(widget.residence),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else {
                return DropdownMenu<String>(
                  label: typeChoice == ""
                      ? Text("Type de bien")
                      : Text(typeChoice),
                  //hintText: "Bâtiment ",
                  onSelected: (String? value) {
                    setState(() {
                      typeChoice = value!;
                    });
                  },
                  dropdownMenuEntries: (snapshot.data ?? [])
                      .map<DropdownMenuEntry<String>>(
                        (value) => DropdownMenuEntry<String>(
                          value: value,
                          label: value,
                        ),
                      )
                      .toList(),
                  width: width / 1.5,
                );
              }
            },
          ),
          Visibility(
            visible: typeChoice == "Appartement",
            child: Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                child: MyTextStyle.lotName(
                    "Selectionnez le bâtiment de votre bien", Colors.black54),
              ),
              FutureBuilder<List<String>>(
                future: getBatimentLot(widget.residence),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else {
                    return DropdownMenu<String>(
                      label:
                          batChoice == "" ? Text("Bâtiment") : Text(batChoice!),
                      //hintText: "Bâtiment ",
                      onSelected: (String? value) {
                        setState(() {
                          batChoice = value;
                        });
                      },
                      dropdownMenuEntries: (snapshot.data ?? [])
                          .map<DropdownMenuEntry<String>>(
                            (value) => DropdownMenuEntry<String>(
                              value: value,
                              label: value,
                            ),
                          )
                          .toList(),
                      width: width / 1.5,
                    );
                  }
                },
              ),
              Visibility(
                visible: batChoice != "",
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 30),
                    child: MyTextStyle.lotName(
                        "Selectionnez le numéro de votre bien", Colors.black54),
                  ),
                  FutureBuilder<List<String>>(
                    future: getSpecificLot(widget.residence),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        return DropdownMenu<String>(
                          label: lotChoice == ""
                              ? Text("Numéro d'appartement ")
                              : Text(lotChoice!),
                          //hintText: "Numéro d'appartement ",
                          onSelected: (String? value) {
                            setState(() {
                              visible = true;
                              lotChoice = value;
                            });
                          },
                          dropdownMenuEntries: (snapshot.data ?? [])
                              .map<DropdownMenuEntry<String>>(
                                (value) => DropdownMenuEntry<String>(
                                  value: value,
                                  label: value,
                                ),
                              )
                              .toList(),
                          width: width / 1.5,
                        );
                      }
                    },
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: getNumLot().isNotEmpty,
        child: BottomAppBar(
            surfaceTintColor: Colors.white,
            padding: EdgeInsets.all(2),
            height: 70,
            child: Container(
                // decoration: BoxDecoration(color: Colors.amber),
                //height: 30,
                //padding: EdgeInsets.only(bottom: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  TextButton(
                    onPressed: () async {
                      String typeBien = getTypeChoice();
                      String batiment = getBatiment();
                      String numLot = getNumLot();
                      String? lotId = await getRefLot();
                      widget.recupererInformationsStep3(
                          typeBien, batiment, numLot, lotId!);
                      // Action à effectuer lorsque le bouton "Suivant" est pressé
                      if (widget.currentPage < 5) {
                        widget.progressController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      'Suivant',
                    ),
                  ),
                ]))),
      ),
    );
  }

  Future<List<String>> getBatimentLot(Residence residence) async {
    List<Lot> lotsTrouves =
        await DataBasesLotServices().getLotByResidence(residence.id);

    Set<String> batimentsUniques =
        Set(); // Ensemble pour stocker les batiments uniques

    // Parcourir chaque lot pour extraire les batiments uniques
    for (Lot lot in lotsTrouves) {
      if (lot.batiment != null) {
        batimentsUniques.add(lot.batiment!);
      }
    }

    // Convertir l'ensemble en liste
    List<String> batimentLots = batimentsUniques.toList();
    return batimentLots;
  }

  Future<List<String>> getSpecificLot(Residence residence) async {
    List<Lot> lotsTrouves =
        await DataBasesLotServices().getLotByResidence(residence.id);

    Set<String> lotsUniques =
        Set(); // Ensemble pour stocker les batiments uniques

    // Parcourir chaque lot pour extraire les batiments uniques
    for (Lot lot in lotsTrouves) {
      if (lot.lot != null) {
        lotsUniques.add(lot.lot!);
      }
    }

    // Convertir l'ensemble en liste
    List<String> lotLots = lotsUniques.toList();
    return lotLots;
  }

  Future<List<String>> getTypeLot(Residence residence) async {
    List<Lot> lotsTrouves =
        await DataBasesLotServices().getLotByResidence(residence.id);

    Set<String> typeLot = Set(); // Ensemble pour stocker les batiments uniques

    // Parcourir chaque lot pour extraire les batiments uniques
    for (Lot lot in lotsTrouves) {
      if (lot.typeLot != null) {
        typeLot.add(lot.typeLot);
      }
    }

    // Convertir l'ensemble en liste
    List<String> typeLots = typeLot.toList();
    return typeLots;
  }

  Future<String?> getlot(String residenceId, String bat, String numlot) async {
    try {
      DataBasesLotServices lotServices = DataBasesLotServices();
      Lot? specificLot =
          await lotServices.getUniqueLot(residenceId, bat, numlot);

      if (specificLot != null) {
        return specificLot.refLot;
      } else {
        print("No lot found for the given parameters.");
      }
    } catch (e) {
      print("Error occurred while fetching lot: $e");
    }
  }
}
