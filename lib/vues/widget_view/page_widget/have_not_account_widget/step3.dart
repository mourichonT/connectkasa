import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/utils/lot_cascade_helper.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class Step3 extends ConsumerStatefulWidget {
  final Residence residence;
  // typeBien, batiment, numLot, refLot (référence métier), lotDocId (ID du
  // document Firestore residences/{id}/lots/{lotDocId}, pour tout ce qui
  // doit ranger/retrouver des données PAR CE LOT précisément, ex: chemin
  // Storage des justificatifs - à ne pas confondre avec refLot).
  final Function(String, String, String, String, String)
      recupererInformationsStep3;
  final int currentPage;
  final PageController progressController;

  const Step3({
    super.key,
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
  String typeChoice = "";
  String? batChoice = "";
  String? lotChoice = "";
  String? refLot = "";
  String? lotDocId = "";
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

  Future<void> resolveLot() async {
    final lot = await getlot(widget.residence.id, batChoice!, lotChoice!);
    refLot = lot?.refLot;
    lotDocId = lot?.id;
  }

  @override
  void initState() {
    super.initState();
    _lotRepository = ref.read(lotRepositoryProvider);
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
                "Selectionnez le type de bien concerné",
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
                        // Les listes bâtiment/numéro sont filtrées par type
                        // de bien (évite de résoudre le mauvais lot si deux
                        // types partagent un jour le même bâtiment/numéro) -
                        // il faut donc les recharger à chaque changement de
                        // type, comme _numLotFuture l'est déjà au choix du
                        // bâtiment.
                        batChoice = "";
                        lotChoice = "";
                        visible = false;
                        _typeBatFuture = getBatimentLot(widget.residence);
                        _numLotFuture = getSpecificLot(widget.residence);
                      });
                    },
                  );
                }
              },
            ),
            Visibility(
              // Bâtiment/numéro s'appliquent à tout type de bien (parking,
              // cave...), pas seulement "Appartement" - sans quoi aucun
              // autre type ne pouvait jamais aller plus loin (le bouton
              // "Suivant" dépend de ce numéro, jamais renseignable).
              visible: typeChoice.isNotEmpty,
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
                            "Numéro",
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
                      await resolveLot();
                      widget.recupererInformationsStep3(
                          typeBien, batiment, numLot, refLot!, lotDocId!);
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

  Future<List<String>> getBatimentLot(Residence residence) {
    // Filtré par type de bien sélectionné : évite de proposer/résoudre le
    // mauvais lot si deux types partagent un jour le même bâtiment/numéro.
    return LotCascadeHelper.batiments(_lotRepository, residence, typeChoice);
  }

  Future<List<String>> getSpecificLot(Residence residence,
      [String? batiment]) {
    // Filtré par type de bien sélectionné, comme getBatimentLot ci-dessus.
    return LotCascadeHelper.numeros(
        _lotRepository, residence, typeChoice, batiment);
  }

  Future<List<String>> getTypeLot(Residence residence) {
    return LotCascadeHelper.typeLots(_lotRepository, residence);
  }

  Future<Lot?> getlot(String residenceId, String bat, String numlot) async {
    final specificLot =
        await LotCascadeHelper.resolveLot(_lotRepository, residenceId, bat, numlot);
    if (specificLot == null) {
      appLog("No lot found for the given parameters.");
    }
    return specificLot;
  }
}
