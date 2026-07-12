import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/core/providers/lot_repository_provider.dart';
import 'package:connect_kasa/core/repositories/lot_repository.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connect_kasa/core/utils/app_logger.dart';
import 'package:connect_kasa/vues/widget_view/components/app_loader.dart';

class Step3 extends ConsumerStatefulWidget {
  final Residence residence;
  final String typeResident;
  final Function(String, String, String, String) recupererInformationsStep3;
  final int currentPage;
  final PageController progressController;

  const Step3({
    super.key,
    required this.typeResident,
    required this.residence,
    required this.recupererInformationsStep3,
    required this.currentPage,
    required this.progressController,
  });

  @override
  ConsumerState<Step3> createState() => _Step3State();
}

class _Step3State extends ConsumerState<Step3> {
  late final ILotRepository _lotRepository;
  bool visible = false;
  late List<Lot?> lotsTrouves;
  late String expressionTypeChoice;
  String typeChoice = "";
  String? batChoice = "";
  String? lotChoice = "";
  String? refLot = "";
  late Future<List<String>> _typeLotFuture;
  late Future<List<String>> _typeBatFuture;
  late Future<List<String>> _numLotFuture;

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
    _lotRepository = ref.read(lotRepositoryProvider);
    expressionTypeChoice =
        widget.typeResident == "Locataire" ? "loué" : "acheté";
    _typeLotFuture = getTypeLot(widget.residence);
    _typeBatFuture = getBatimentLot(widget.residence);
    _numLotFuture = getSpecificLot(widget.residence);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MyTextStyle.lotName(
                "Selectionnez le type de bien que vous avez $expressionTypeChoice",
                Colors.black54),
            const SizedBox(
              height: 30,
            ),
            FutureBuilder<List<String>>(
              future: _typeLotFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoader();
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else {
                  return MyDropDownMenu(
                    width,
                    "Type de bien",
                    typeChoice.isEmpty
                        ? "Sélectionnez le type de bien"
                        : typeChoice,
                    false,
                    items: snapshot.data ?? [],
                    onValueChanged: (value) {
                      setState(() {
                        appLog(value);
                        typeChoice = value;
                      });
                    },
                  );
                }
              },
            ),
            Visibility(
              visible: typeChoice == "Appartement",
              child: Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: MyTextStyle.lotName(
                      "Selectionnez le bâtiment de votre bien", Colors.black54),
                ),
                FutureBuilder<List<String>>(
                  future: _typeBatFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppLoader();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return MyDropDownMenu(
                        width,
                        "Bâtiment",
                        batChoice == ""
                            ? "Sélectionnez le bâtiment"
                            : batChoice!,
                        false,
                        items: snapshot.data ?? [],
                        onValueChanged: (value) {
                          setState(() {
                            batChoice = value;
                            lotChoice = "";
                            visible = false;
                            _numLotFuture =
                                getSpecificLot(widget.residence, value);
                          });
                        },
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
                          "Selectionnez le numéro de votre bien",
                          Colors.black54),
                    ),
                    FutureBuilder<List<String>>(
                      future: _numLotFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoader();
                        } else if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        } else {
                          return MyDropDownMenu(
                            width,
                            "Numéro d'appartement",
                            lotChoice == ""
                                ? "Sélectionnez le numéro"
                                : lotChoice!,
                            false,
                            items: snapshot.data ?? [],
                            onValueChanged: (value) {
                              setState(() {
                                visible = true;
                                lotChoice = value;
                              });
                            },
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
      ),
      bottomNavigationBar: Visibility(
        visible: getNumLot().isNotEmpty,
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
                    onPressed: () async {
                      String typeBien = getTypeChoice();
                      String batiment = getBatiment();
                      String numLot = getNumLot();
                      String? lotId = await getRefLot();
                      widget.recupererInformationsStep3(
                          typeBien, batiment, numLot, lotId!);
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

  Future<List<String>> getBatimentLot(Residence residence) async {
    List<Lot> lotsTrouves = await _lotRepository
        .getLotByResidence(residence.id)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));

    Set<String> batimentsUniques = {};

    for (Lot lot in lotsTrouves) {
      if (lot.batiment != null) {
        batimentsUniques.add(lot.batiment!);
      }
    }

    List<String> batimentLots = batimentsUniques.toList();
    return batimentLots;
  }

  Future<List<String>> getSpecificLot(Residence residence,
      [String? batiment]) async {
    List<Lot> lotsTrouves = await _lotRepository
        .getLotByResidence(residence.id)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));

    Set<String> lotsUniques = {};

    for (Lot lot in lotsTrouves) {
      if (lot.lot != null && (batiment == null || lot.batiment == batiment)) {
        lotsUniques.add(lot.lot!);
      }
    }

    List<String> lotLots = lotsUniques.toList();
    return lotLots;
  }

  Future<List<String>> getTypeLot(Residence residence) async {
    List<Lot> lotsTrouves = await _lotRepository
        .getLotByResidence(residence.id)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));

    Set<String> typeLot = {};

    for (Lot lot in lotsTrouves) {
      typeLot.add(lot.typeLot);
    }

    List<String> typeLots = typeLot.toList();
    return typeLots;
  }

  Future<String?> getlot(String residenceId, String bat, String numlot) async {
    try {
      Lot? specificLot = await _lotRepository
          .getUniqueLot(residenceId, bat, numlot)
          .then((result) =>
              result.when(success: (v) => v, failure: (error) => throw error));

      if (specificLot != null) {
        return specificLot.refLot;
      } else {
        appLog("No lot found for the given parameters.");
      }
    } catch (e) {
      appLog("Error occurred while fetching lot: $e");
    }
    return null;
  }
}
