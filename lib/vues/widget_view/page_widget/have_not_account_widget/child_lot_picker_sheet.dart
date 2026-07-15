import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/utils/lot_cascade_helper.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre un sélecteur de lot enfant (type/bâtiment/numéro, comme Step3) mais
/// filtré aux lots isLinkable == true de la résidence - garde-fou déjà posé
/// par un CS member à la création du lot (manage_list_lot.dart), jamais par
/// le propriétaire. Renvoie le Lot complet résolu (pas juste des ids), pour
/// que l'appelant (Step2) puisse lire idLocataire avant de l'ajouter à sa
/// liste de lots enfants en attente.
Future<Lot?> showChildLotPicker(BuildContext context, Residence residence) {
  return showModalBottomSheet<Lot>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: ChildLotPickerSheet(residence: residence),
    ),
  );
}

class ChildLotPickerSheet extends ConsumerStatefulWidget {
  final Residence residence;

  const ChildLotPickerSheet({super.key, required this.residence});

  @override
  ConsumerState<ChildLotPickerSheet> createState() =>
      _ChildLotPickerSheetState();
}

class _ChildLotPickerSheetState extends ConsumerState<ChildLotPickerSheet> {
  late final ILotRepository _lotRepository;
  String typeChoice = "";
  String? batChoice = "";
  String? lotChoice = "";
  late Future<List<String>> _typeLotFuture;
  late Future<List<String>> _typeBatFuture;
  late Future<List<String>> _numLotFuture;

  bool _onlyLinkable(Lot lot) => lot.isLinkable;

  @override
  void initState() {
    super.initState();
    _lotRepository = ref.read(lotRepositoryProvider);
    _typeLotFuture = LotCascadeHelper.typeLots(_lotRepository, widget.residence,
        filter: _onlyLinkable);
    _typeBatFuture = LotCascadeHelper.batiments(
        _lotRepository, widget.residence, typeChoice,
        filter: _onlyLinkable);
    _numLotFuture = LotCascadeHelper.numeros(
        _lotRepository, widget.residence, typeChoice, null, _onlyLinkable);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MyTextStyle.lotName("Ajouter un lot rattaché", Colors.black54),
            const SizedBox(height: 20),
            FutureBuilder<List<String>>(
              future: _typeLotFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoader();
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
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
                      typeChoice = value;
                      batChoice = "";
                      lotChoice = "";
                      _typeBatFuture = LotCascadeHelper.batiments(
                          _lotRepository, widget.residence, typeChoice,
                          filter: _onlyLinkable);
                      _numLotFuture = LotCascadeHelper.numeros(_lotRepository,
                          widget.residence, typeChoice, null, _onlyLinkable);
                    });
                  },
                );
              },
            ),
            Visibility(
              visible: typeChoice.isNotEmpty,
              child: Column(children: [
                const SizedBox(height: 20),
                FutureBuilder<List<String>>(
                  future: _typeBatFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppLoader();
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    return MyDropDownMenu(
                      width,
                      "Bâtiment",
                      batChoice == "" ? "Sélectionnez le bâtiment" : batChoice!,
                      false,
                      items: snapshot.data ?? [],
                      onValueChanged: (value) {
                        setState(() {
                          batChoice = value;
                          lotChoice = "";
                          _numLotFuture = LotCascadeHelper.numeros(
                              _lotRepository,
                              widget.residence,
                              typeChoice,
                              value,
                              _onlyLinkable);
                        });
                      },
                    );
                  },
                ),
                Visibility(
                  visible: batChoice != "",
                  child: Column(children: [
                    const SizedBox(height: 20),
                    FutureBuilder<List<String>>(
                      future: _numLotFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoader();
                        } else if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }
                        return MyDropDownMenu(
                          width,
                          "Numéro",
                          lotChoice == "" ? "Sélectionnez le numéro" : lotChoice!,
                          false,
                          items: snapshot.data ?? [],
                          onValueChanged: (value) {
                            setState(() => lotChoice = value);
                          },
                        );
                      },
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (batChoice != null &&
                      batChoice!.isNotEmpty &&
                      lotChoice != null &&
                      lotChoice!.isNotEmpty)
                  ? () async {
                      final lot = await LotCascadeHelper.resolveLot(
                          _lotRepository,
                          widget.residence.id,
                          batChoice!,
                          lotChoice!);
                      if (!context.mounted) return;
                      Navigator.of(context).pop(lot);
                    }
                  : null,
              child: const Text("Ajouter ce lot"),
            ),
          ],
        ),
      ),
    );
  }
}
