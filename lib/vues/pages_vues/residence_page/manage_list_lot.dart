import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/repositories/firestore_lot_repository.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/structure_residence.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/residence_repository.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/core/utils/app_logger.dart';

class ManageListLot extends StatefulWidget {
  final Color color;
  final Residence residence;

  const ManageListLot({
    super.key,
    required this.color,
    required this.residence,
  });

  @override
  State<ManageListLot> createState() => _ManageListLotState();
}

class _ManageListLotState extends State<ManageListLot> {
  final List<Lot> lots = [];
  List<StructureResidence> buildings = [];

  // État d'ouverture des cartes : purement local (UI), jamais persisté en
  // base (Lot.toJsonForDb() exclut déjà userLotDetails). Basé sur
  // l'identité de l'objet, comme ObjectKey ci-dessous.
  final Set<Lot> _expandedLots = {};

  // Un bâtiment peut avoir des dizaines de lots - regroupés dans un menu
  // déroulant (ExpansionTile) replié par défaut, plutôt que tous affichés
  // en une longue liste. État purement local (clé = nom de groupe).
  final Set<String> _expandedBuildingGroups = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Regroupement visuel par bâtiment : figé tant que le lot n'est pas
  // enregistré, pour que la carte ne saute pas d'un groupe à l'autre
  // pendant la saisie (dès qu'on choisit l'emplacement). Mis à jour
  // uniquement après un enregistrement réussi (_saveLots).
  final Map<Lot, String> _groupKeyForLot = {};

  String _groupKeyFor(Lot lot) {
    return _groupKeyForLot.putIfAbsent(lot, () => _computeGroupKey(lot));
  }

  String _computeGroupKey(Lot lot) {
    return lot.batiment?.trim().isNotEmpty == true
        ? lot.batiment!.trim()
        : "Sans bâtiment";
  }

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final IResidenceRepository _residenceServices =
      FirestoreResidenceRepository();
  final ILotRepository _lotServices = FirestoreLotRepository();
  List<String> nameBuildings = [];
  String typeBuilding = "";

  @override
  void initState() {
    super.initState();
    _loadLots();
    _loadBuildings();
    appLog("ID résidence = ${widget.residence.id}");
  }

  Future<void> _loadBuildings() async {
    try {
      final fetched = await _residenceServices
          .getStructuresByResidence(widget.residence.id)
          .then((result) =>
              result.when(success: (v) => v, failure: (error) => throw error));
      if (mounted) {
        setState(() {
          nameBuildings = fetched.map((b) => "${b.type} ${b.name}").toList()
            ..sort((a, b) {
              // Trier par longueur d'abord, puis alphabétiquement si égalité
              if (a.length != b.length) {
                return a.length.compareTo(b.length);
              }
              return a.compareTo(b);
            });

          appLog("Nom des bâtiments : $nameBuildings");
        });
      }
    } catch (e) {
      appLog("Erreur lors du chargement des bâtiments : $e");
    }
  }

  Future<void> _loadLots() async {
    final fetchedLots = await _lotServices
        .getLotByResidence(widget.residence.id)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Lot>[]));
    setState(() {
      lots.clear();
      lots.addAll(fetchedLots);
      // Toutes les cartes sont fermées au chargement.
      _expandedLots.clear();
      _groupKeyForLot.clear();
    });
  }

  void _addLot() {
    setState(() {
      lots.add(
        Lot(
          batiment: '',
          refLot: '',
          typeLot: '',
          type: '',
          idProprietaire: [],
          residenceId: widget.residence.id,
          residenceData: {},
          userLotDetails: {},
        ),
      );
    });
  }

  void _removeLot(int index, String? lotId) async {
    final prefix = 'lot_$index';
    for (final field in [
      'refLot',
      'typeLot',
      'type',
      'batiment',
      'lot',
    ]) {
      final controllerKey = '${prefix}_$field';
      _controllers[controllerKey]?.dispose();
      _controllers.remove(controllerKey); // 🔧 Supprime la clé

      _focusNodes[controllerKey]?.dispose();
      _focusNodes.remove(controllerKey); // 🔧 Supprime la clé
    }

    // Un lot jamais enregistré (juste ajouté localement, pas encore
    // sauvegardé) n'a pas encore d'ID : rien à supprimer côté Firestore.
    if (lotId != null) {
      await _lotServices.deleteLot(widget.residence.id, lotId);
    }

    setState(() {
      lots.removeAt(index);
    });
  }

  TextEditingController _initController(String key, String? value) {
    _controllers.putIfAbsent(key, () => TextEditingController());
    _controllers[key]!.text = value ?? '';
    _focusNodes.putIfAbsent(key, () => FocusNode());
    return _controllers[key]!;
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _focusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    // Filtre de recherche (N°, référence administrative ou bâtiment) - un
    // bâtiment n'apparaît dans la liste que s'il contient au moins un lot
    // correspondant, cf. boucle ci-dessous.
    final String query = _searchQuery.trim().toLowerCase();
    final bool isSearching = query.isNotEmpty;
    bool matchesQuery(Lot lot) {
      if (query.isEmpty) return true;
      return [lot.lot, lot.refLot, lot.batiment]
          .any((f) => (f ?? '').toLowerCase().contains(query));
    }

    // Regrouper les lots par nom de bâtiment (clé figée jusqu'à
    // l'enregistrement, voir _groupKeyFor)
    Map<String, List<Lot>> lotsGroupedByBuilding = {};
    for (var lot in lots) {
      if (!matchesQuery(lot)) continue;
      String key = _groupKeyFor(lot);
      lotsGroupedByBuilding.putIfAbsent(key, () => []);
      lotsGroupedByBuilding[key]!.add(lot);
    }
    // Tri croissant par "order" au sein de chaque bâtiment - un lot sans
    // order (jamais positionné manuellement) est relégué en fin de groupe
    // plutôt que de perturber l'ordre de ceux déjà rangés.
    for (final group in lotsGroupedByBuilding.values) {
      group.sort((a, b) {
        if (a.order == null && b.order == null) return 0;
        if (a.order == null) return 1;
        if (b.order == null) return -1;
        return a.order!.compareTo(b.order!);
      });
    }
    String getFullBuildingName(String buildingName) {
      final index = buildings.indexWhere((b) => b.name.trim() == buildingName);
      if (index != -1) {
        return nameBuildings[index];
      }
      return buildingName; // fallback
    }

    // Trier les groupes par longueur de nom puis alphabétiquement
    final sortedEntries = lotsGroupedByBuilding.entries.toList()
      ..sort((a, b) {
        final nameA = getFullBuildingName(a.key);
        final nameB = getFullBuildingName(b.key);

        if (nameA.length != nameB.length) {
          return nameA.length.compareTo(nameB.length);
        }
        return nameA.compareTo(nameB);
      });

    // Fonction pour afficher le nom complet (type + nom) à partir du nom

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Gestion des Lots",
          Colors.black87,
          SizeFont.h1.size,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextFieldWidget(
                    label: "Rechercher un lot",
                    text: "N°, référence ou bâtiment...",
                    controller: _searchController,
                    isEditable: true,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  // Affichage groupé des lots par bâtiment, repliés par défaut
                  // dans un menu déroulant (un bâtiment peut contenir des
                  // dizaines de lots) - automatiquement dépliés pendant une
                  // recherche, pour ne pas avoir à ouvrir chaque bâtiment
                  // manuellement afin de voir un résultat qui matche.
                  ...sortedEntries.map((entry) {
                    final buildingName = entry.key;
                    final lotsForBuilding = entry.value;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        key: ValueKey('bldg_${buildingName}_$isSearching'),
                        initiallyExpanded: isSearching ||
                            _expandedBuildingGroups.contains(buildingName),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedBuildingGroups.add(buildingName);
                            } else {
                              _expandedBuildingGroups.remove(buildingName);
                            }
                          });
                        },
                        title: MyTextStyle.lotName(
                            "${getFullBuildingName(buildingName)} (${lotsForBuilding.length})",
                            Colors.black87,
                            SizeFont.h1.size),
                        children: [
                          ...lotsForBuilding.asMap().entries.map((lotEntry) {
                            final index = lots.indexOf(lotEntry.value);
                            final lot = lotEntry.value;
                            final prefix = 'lot_$index';

                            final refLotController =
                                _initController('${prefix}_refLot', lot.refLot);
                            final lotNameController =
                                _initController('${prefix}_lot', lot.lot);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: ExpansionTile(
                                key: ObjectKey(lot),
                                initiallyExpanded: _expandedLots.contains(lot),
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    if (expanded) {
                                      _expandedLots.add(lot);
                                    } else {
                                      _expandedLots.remove(lot);
                                    }
                                  });
                                },
                                title: MyTextStyle.lotName(
                                  lot.lot ?? "Nouveau Lot",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        CustomTextFieldWidget(
                                          label:
                                              "Référence administrative du lot",
                                          controller: refLotController,
                                          isEditable: true,
                                          onChanged: (val) => lot.refLot = val,
                                        ),
                                        const SizedBox(height: 10),
                                        MyDropDownMenu(
                                          height: 90,
                                          width,
                                          "Type de lot ",
                                          lot.typeLot,
                                          false,
                                          items: TypeList.typeLot,
                                          onValueChanged: (value) {
                                            setState(() {
                                              lot.typeLot = value;
                                              // Suggestion par défaut selon le type -
                                              // ajustable ensuite via le switch
                                              // ci-dessous (ex: un local commercial
                                              // exceptionnellement rattachable).
                                              lot.isLinkable =
                                                  Lot.defaultIsLinkableForType(
                                                      value);
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: MyTextStyle.lotDesc(
                                                "Rattachable à un autre lot (ex: parking, cave)",
                                                SizeFont.h3.size,
                                              ),
                                            ),
                                            Switch(
                                              value: lot.isLinkable,
                                              onChanged: (value) {
                                                setState(() {
                                                  lot.isLinkable = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        MyDropDownMenu(
                                          height: 90,
                                          width,
                                          "Emplacement ",
                                          lot.batiment ?? "",
                                          false,
                                          items: nameBuildings,
                                          onValueChanged: (value) {
                                            setState(() {
                                              lot.batiment = value;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        CustomTextFieldWidget(
                                          label: "N°",
                                          controller: lotNameController,
                                          isEditable: true,
                                          onChanged: (val) => lot.lot = val,
                                        ),
                                        const SizedBox(height: 10),
                                        _removeLotButton(index, lot),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  Center(
                    child: ButtonAdd(
                      color: Colors.transparent,
                      icon: Icons.add,
                      text: "Ajouter un lot",
                      size: SizeFont.h3.size,
                      horizontal: 20,
                      vertical: 10,
                      colorText: widget.color,
                      borderColor: Colors.transparent,
                      function: _addLot,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Center(
                child: ButtonAdd(
                  color: widget.color,
                  icon: Icons.save,
                  text: "Enregistrer les lots",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: Colors.white,
                  borderColor: Colors.transparent,
                  function: _saveLots,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _removeLotButton(int index, Lot lot) {
    final hasProprietaire =
        lot.idProprietaire != null && lot.idProprietaire!.isNotEmpty;
    final hasLocataire = lot.idLocataire != null && lot.idLocataire!.isNotEmpty;

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          !hasProprietaire && !hasLocataire
              ? _removeLot(index, lot.id)
              : ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      hasProprietaire
                          ? "Le lot est déjà rattaché à un propriétaire, il n'est plus possible de le supprimer."
                          : "Le lot est déjà rattaché à un locataire, il n'est plus possible de le supprimer.",
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
        },
        icon: const Icon(Icons.delete_forever, color: Colors.black54),
        label: MyTextStyle.postDesc(
          "Supprimer le lot",
          SizeFont.h3.size,
          Colors.black54,
        ),
      ),
    );
  }

  void _saveLots() async {
    // Écarte silencieusement les brouillons abandonnés : un lot jamais
    // enregistré (id == null) et entièrement vide n'est pas une erreur de
    // saisie à bloquer, juste une carte à oublier. Un lot partiellement
    // rempli garde le comportement actuel (bloque tant qu'il est incomplet).
    setState(() {
      lots.removeWhere((lot) {
        final isPending = lot.id == null || lot.id!.isEmpty;
        final isBlank = lot.refLot.trim().isEmpty &&
            (lot.batiment?.trim().isEmpty ?? true) &&
            (lot.lot?.trim().isEmpty ?? true) &&
            lot.typeLot.trim().isEmpty;
        return isPending && isBlank;
      });
    });

    final Set<String> refLotSet = {};
    final Set<String> batimentLotSet = {};
    final List<String> duplicateErrors = [];

    for (int i = 0; i < lots.length; i++) {
      final lot = lots[i];

      final refLot = lot.refLot.trim();
      final building = lot.batiment?.trim() ?? '';
      final number = lot.lot?.trim() ?? '';
      final combo = "$building-$number";

      // Vérifie refLot
      if (refLot.isEmpty) {
        duplicateErrors.add("Le lot à l’index $i n’a pas de 'refLot'");
      } else if (!refLotSet.add(refLot)) {
        duplicateErrors.add("Doublon de 'refLot' : $refLot");
      }

      // Vérifie batiment + lot
      if (building.isEmpty || number.isEmpty) {
        duplicateErrors
            .add("Le lot à l’index $i est incomplet (bâtiment ou numéro vide)");
      } else if (!batimentLotSet.add(combo)) {
        duplicateErrors.add("Doublon : bâtiment '$building', lot '$number'");
      }
    }

    if (duplicateErrors.isNotEmpty) {
      appLog("Validation des lots échouée : $duplicateErrors");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(duplicateErrors.join('\n')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    // Tous les lots sont valides, on peut les enregistrer
    try {
      for (var lot in lots) {
        await _lotServices.createOrUpdateLot(widget.residence.id, lot);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lots enregistrés avec succès"),
        ),
      );

      setState(() {
        _expandedLots.clear();
        // Les cartes rejoignent maintenant leur vrai groupe (bâtiment
        // choisi pendant la saisie).
        for (var lot in lots) {
          _groupKeyForLot[lot] = _computeGroupKey(lot);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
