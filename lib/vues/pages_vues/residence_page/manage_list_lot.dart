import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/elements_list.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';

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
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final DataBasesResidenceServices _residenceServices =
      DataBasesResidenceServices();
  final DataBasesLotServices _lotServices = DataBasesLotServices();
  List<String> nameBuildings = [];
  String typeBuilding = "";

  @override
  void initState() {
    super.initState();
    _loadLots();
    _loadBuildings();
    print("ID résidence = ${widget.residence.id}");
  }

  Future<void> _loadBuildings() async {
    if (widget.residence.id == null) return;

    try {
      final fetched = await _residenceServices
          .getStructuresByResidence(widget.residence.id!);
      if (mounted) {
        setState(() {
          buildings = fetched;
          nameBuildings = fetched
              .where((b) => b.type != null && b.name != null)
              .map((b) => "${b.type} ${b.name}")
              .toList();
          print("Nom des bâtiments : $nameBuildings");
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des bâtiments : $e");
    }
  }

  Future<void> _loadLots() async {
    if (widget.residence.id != null) {
      final fetchedLots =
          await _lotServices.getLotByResidence(widget.residence.id);
      for (var lot in fetchedLots) {
        lot.userLotDetails['isExpanded'] = false;
      }
      setState(() {
        lots.clear();
        lots.addAll(fetchedLots);
      });
    }
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
          residenceId: widget.residence.id!,
          residenceData: {},
          userLotDetails: {},
        ),
      );
    });
  }

  void _removeLot(int index) {
    final prefix = 'lot_$index';
    for (final field in [
      'refLot',
      'typeLot',
      'type',
      'batiment',
      'lot',
      'refGerance',
    ]) {
      _controllers['${prefix}_$field']?.dispose();
      _focusNodes['${prefix}_$field']?.dispose();
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

    // Liste des noms uniquement (pour tri et regroupement)
    final buildingNamesOnly = buildings.map((b) => b.name.trim()).toList();

    // Regrouper les lots par nom de bâtiment (batiment dans lot)
    Map<String, List<Lot>> lotsGroupedByBuilding = {};
    for (var lot in lots) {
      String key = lot.batiment?.trim().isNotEmpty == true
          ? lot.batiment!.trim()
          : "Sans bâtiment";
      lotsGroupedByBuilding.putIfAbsent(key, () => []);
      lotsGroupedByBuilding[key]!.add(lot);
    }

    // Trier les groupes selon l’ordre de buildingNamesOnly
    final sortedEntries = lotsGroupedByBuilding.entries.toList()
      ..sort((a, b) {
        int indexA = buildingNamesOnly.indexOf(a.key);
        int indexB = buildingNamesOnly.indexOf(b.key);
        if (indexA == -1) indexA = 9999;
        if (indexB == -1) indexB = 9999;
        return indexA.compareTo(indexB);
      });

    // Fonction pour afficher le nom complet (type + nom) à partir du nom
    String getFullBuildingName(String buildingName) {
      final index = buildings.indexWhere((b) => b.name.trim() == buildingName);
      if (index != -1) {
        return nameBuildings[index];
      }
      return buildingName; // fallback
    }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage groupé des lots par bâtiment
            ...sortedEntries.map((entry) {
              final buildingName = entry.key;
              final lotsForBuilding = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getFullBuildingName(buildingName),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...lotsForBuilding.asMap().entries.map((lotEntry) {
                    final index = lots.indexOf(lotEntry.value);
                    final lot = lotEntry.value;
                    final prefix = 'lot_$index';

                    final refLotController =
                        _initController('${prefix}_refLot', lot.refLot);
                    final lotNameController =
                        _initController('${prefix}_lot', lot.lot);
                    final isExpanded =
                        lot.userLotDetails['isExpanded'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        key: ObjectKey(lot),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            lot.userLotDetails['isExpanded'] = expanded;
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
                                  label: "Référence administrative du lot",
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
                                    });
                                  },
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
                                _removeLotButton(index),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),

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
            const SizedBox(height: 30),
            Center(
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
          ],
        ),
      ),
    );
  }

  Widget _removeLotButton(int index) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _removeLot(index),
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
    final Set<String> refLotSet = {};
    final Set<String> batimentLotSet = {};
    final List<String> duplicateErrors = [];

    for (int i = 0; i < lots.length; i++) {
      final lot = lots[i];

      final refLot = lot.refLot?.trim() ?? '';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreurs détectées :\n${duplicateErrors.join('\n')}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    // Tous les lots sont valides, on peut les enregistrer
    try {
      for (var lot in lots) {
        await _lotServices.createOrUpdateLot(widget.residence.id!, lot);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lots enregistrés avec succès"),
        ),
      );

      setState(() {
        for (var lot in lots) {
          lot.userLotDetails['isExpanded'] = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
