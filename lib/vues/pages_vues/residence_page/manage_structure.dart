import 'package:connect_kasa/controllers/features/agency_search_flow.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/search_agency_module.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart'; // Importation ajoutée
import 'package:connect_kasa/models/enum/elements_list.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart'; // Gardez cette importation si elle est utilisée ailleurs
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';
import 'package:connect_kasa/vues/widget_view/components/agency_search_result_list.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';

class ManageStructure extends StatefulWidget {
  final Residence residence;
  final Color color;
  // Si renseigné, la carte de ce bâtiment s'ouvre automatiquement et défile
  // à l'écran (ex: navigation depuis la carte d'exception d'un syndic sur
  // management_res_info_g.dart).
  final String? initialExpandedStructureId;

  ManageStructure({
    super.key,
    required this.residence,
    required this.color,
    this.initialExpandedStructureId,
  });

  @override
  State<ManageStructure> createState() => ManageStructureState();
}

class ManageStructureState extends State<ManageStructure> {
  final AgencySearchFlow _flow = AgencySearchFlow(serviceType: 'serviceSyndic');
  final DataBasesResidenceServices _residenceServices =
      DataBasesResidenceServices();
  List<Agent> agents = [];
  List<StructureResidence> buildings = [];

  // État d'ouverture des cartes : purement local (UI), jamais persisté en
  // base. Basé sur l'identité de l'objet, donc il suit le bon bâtiment
  // même si la liste est réordonnée.
  final Set<StructureResidence> _expandedBuildings = {};
  // Clé par bâtiment (id Firestore), pour pouvoir faire défiler jusqu'à une
  // carte précise après navigation depuis un autre écran.
  final Map<String, GlobalKey> _cardKeys = {};
  List<Agency> searchResults = [];
  Agent? selectedAgent;
  String buildingType = "";

  bool isSearching = false;
  List<String> itemsElements = [];
  bool _itemSelected = false;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadBuildings();
    itemsElements = ElementsList.elements();
  }

  Future<void> _loadBuildings() async {
    if (widget.residence.id != null) {
      final fetchedBuildings = await _residenceServices
          .getStructuresByResidence(widget.residence.id!);

      // Résout les syndics référencés dans Gerance depuis la source à jour
      // plutôt que de se fier à une copie potentiellement figée.
      for (final building in fetchedBuildings) {
        if (building.geranceRef != null) {
          building.syndicAgency = await _flow.resolve(building.geranceRef!);
        }
      }

      setState(() {
        buildings = fetchedBuildings;
        // Toutes les cartes sont fermées au chargement, sauf celle ciblée
        // par la navigation entrante.
        _expandedBuildings.clear();
        if (widget.initialExpandedStructureId != null) {
          final target = buildings.firstWhere(
            (b) => b.id == widget.initialExpandedStructureId,
            orElse: () => StructureResidence(name: '', type: ''),
          );
          if (target.id != null) {
            _expandedBuildings.add(target);
          }
        }
      });

      if (widget.initialExpandedStructureId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _cardKeys[widget.initialExpandedStructureId];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } else {
      buildings = [];
    }
  }

  Future<void> searchAgencyByEmail(
      String emailPart, StructureResidence building) async {
    setState(() {
      isSearching = true;
    });

    final results = await _flow.search(emailPart);

    setState(() {
      if (results.isEmpty) {
        // Aucun match dans Gerance : entrée custom, non référencée.
        building.syndicAgency = _flow.buildCustomAgency(emailPart);
        building.geranceRef = null;
        searchResults = [building.syndicAgency!];
        _itemSelected = true;
      } else {
        searchResults = results;
      }
      isSearching = false;
    });
  }

  void addBuilding() {
    setState(() {
      final building = StructureResidence(name: '', type: '');
      buildings.add(building);
      _expandedBuildings.add(building);
    });
  }

  void disposeControllerForBuilding(int index) {
    _controllers['building_name_$index']?.dispose();
    _focusNodes['building_name_$index']?.dispose();
    _controllers['building_elements_$index']?.dispose();
    _focusNodes['building_elements_$index']?.dispose();
    _controllers['building_etage_$index']?.dispose();
    _focusNodes['building_etage_$index']?.dispose();
    _controllers['building_undergroundLevel_$index']?.dispose();
    _focusNodes['building_undergroundLevel_$index']?.dispose();
    _controllers['building_ref_gerance_$index']?.dispose();
    _focusNodes['building_ref_gerance_$index']?.dispose();
    _controllers['agency_search_controller_$index']?.dispose();
    _focusNodes['agency_search_controller_$index']?.dispose();
  }

  void removeBuilding(int index, String? structureId) async {
    setState(() {
      buildings.removeAt(index);
    });
    if (structureId != null) {
      await _residenceServices.removeStructure(
          widget.residence.id!, structureId);
    }
  }

  Future<void> saveBuildings() async {
    if (widget.residence.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Impossible de sauvegarder : ID de résidence manquant.")),
      );
      return;
    }

    for (int i = 0; i < buildings.length; i++) {
      final building = buildings[i];

      final nameController = _controllers['building_name_$i'];
      final typeController = building.type;

      if (nameController == null || nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Le nom de la structure ne peut pas être vide."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _expandedBuildings.add(building);
        });
        return;
      }

      if (typeController.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Le type de la structure '${building.name}' ne peut pas être vide."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _expandedBuildings.add(building);
        });
        return;
      }
    }
    try {
      for (var building in buildings) {
        print(building.toJson());
        await _residenceServices.saveStructure(widget.residence.id!, building);
        _expandedBuildings.remove(building);
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Structures mises à jour avec succès")),
      );

      _loadBuildings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur lors de la sauvegarde des structures : $e")),
      );
    }
  }

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, focusNode) => focusNode.dispose());
    super.dispose();
  }

  TextEditingController _initAndGetController(String key, String? initialText) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialText ?? '');
    }
    _focusNodes.putIfAbsent(key, () => FocusNode());
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Configuration de la résidence",
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
            MyTextStyle.postDesc(
                "Modélisez votre résidence, ajoutez les structures représentant chaque bâtiment et ses caractéristiques.",
                SizeFont.h2.size,
                Colors.black54,
                fontweight: FontWeight.normal,
                textAlign: TextAlign.justify),
            const SizedBox(height: 20),
            ...buildings.asMap().entries.map((entry) {
              final index = entry.key;
              final building = entry.value;

              final nameController =
                  _initAndGetController('building_name_$index', building.name);
              final elementsController = _initAndGetController(
                  'building_elements_$index', building.elements?.join(', '));

              // Calculer la longueur initiale des étages pour l'affichage dans le champ
              final initialEtageLength =
                  (building.etage?.contains("RDC") ?? false)
                      ? (building.etage?.length ?? 0)
                      : (building.etage?.length ?? 0) +
                          1; // Si RDC n'existe pas, ajoutez-le virtuellement
              final etageController = _initAndGetController(
                  'building_etage_$index', initialEtageLength.toString());

              // Le contrôleur pour undergroundLevel n'est plus directement lié à une propriété séparée
              final undergroundLevelController = _initAndGetController(
                  'building_undergroundLevel_$index',
                  building.etage
                      ?.where((e) => e.startsWith("Sous-sol"))
                      .length
                      .toString());

              final _lookupController = _initAndGetController(
                  'building_ref_gerance_$index',
                  building.syndicAgency?.syndic?.mail ?? "");

              final agencySearchController = _initAndGetController(
                  'agency_search_controller_$index',
                  building.syndicAgency?.syndic?.mail ?? "");

              final cardKey = building.id == null
                  ? null
                  : _cardKeys.putIfAbsent(building.id!, () => GlobalKey());

              return Card(
                key: cardKey,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ExpansionTile(
                  key: ObjectKey(building),
                  initiallyExpanded: _expandedBuildings.contains(building),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedBuildings.add(building);
                      } else {
                        _expandedBuildings.remove(building);
                      }
                    });
                  },
                  tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyTextStyle.lotName(
                              building.name.isNotEmpty
                                  ? "${building.type} ${building.name}"
                                  : "Nouveau Bâtiment",
                              Colors.black87,
                              SizeFont.h2.size,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextFieldWidget(
                            label: "Nom du Bâtiment",
                            controller: nameController,
                            isEditable: true,
                            onChanged: (val) => building.name = val,
                          ),
                          const SizedBox(height: 10),
                          MyDropDownMenu(
                            height: 90,
                            width,
                            "Type de structure",
                            building.type,
                            false,
                            items: ElementsList.structureType(),
                            onValueChanged: (value) {
                              setState(() {
                                building.type = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: MyTextStyle.lotName(
                                "Ajouter les éléments qui composent votre bâtiment",
                                Colors.black87,
                                SizeFont.h3.size),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              Center(
                                child: Wrap(
                                  spacing: 5.0,
                                  children:
                                      itemsElements.map((String itemsElement) {
                                    return FilterChip(
                                      label: MyTextStyle.lotDesc(
                                          itemsElement, SizeFont.h3.size),
                                      selected: building.elements
                                              ?.contains(itemsElement) ??
                                          false,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          building.elements ??= [];
                                          if (selected) {
                                            building.elements!
                                                .add(itemsElement);
                                          } else {
                                            building.elements!
                                                .remove(itemsElement);
                                          }
                                          elementsController.text =
                                              building.elements!.join(', ');
                                        });
                                      },
                                      backgroundColor: const Color(0xFFF5F6F9),
                                      selectedColor:
                                          Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      side: BorderSide(
                                        color: (building.elements
                                                    ?.contains(itemsElement) ??
                                                false)
                                            ? Theme.of(context).primaryColor
                                            : const Color(0xFFF5F6F9),
                                        width: 2,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      TextEditingController newItemController =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: MyTextStyle.lotName(
                                            'Ajouter des éléments',
                                            Colors.black87,
                                            SizeFont.h3.size),
                                        content: TextField(
                                          controller: newItemController,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Entrez un nouvel élément',
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: MyTextStyle.lotName(
                                                'Annuler',
                                                Colors.black54,
                                                SizeFont.h3.size,
                                                FontWeight.normal),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: MyTextStyle.lotName(
                                                'Ajouter',
                                                Theme.of(context).primaryColor),
                                            onPressed: () {
                                              setState(() {
                                                if (newItemController
                                                    .text.isNotEmpty) {
                                                  // Assurez-vous que building.elements est initialisé
                                                  building.elements ??= [];
                                                  // Ajoutez le nouvel élément à la liste des éléments du bâtiment
                                                  building.elements!.add(
                                                      newItemController.text);
                                                  // Mettez à jour itemsElements si nécessaire pour que le FilterChip soit disponible
                                                  // Ceci est important si vous voulez que le nouvel élément apparaisse comme un FilterChip sélectionnable
                                                  // Si itemsElements est une liste fixe, vous devrez peut-être la rendre dynamique
                                                  if (!itemsElements.contains(
                                                      newItemController.text)) {
                                                    itemsElements.add(
                                                        newItemController.text);
                                                  }
                                                  // Mettez à jour le contrôleur de texte principal si vous l'utilisez
                                                  elementsController.text =
                                                      building.elements!
                                                          .join(', ');
                                                }
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add),
                                    MyTextStyle.lotName(
                                        'Ajouter des éléments',
                                        Theme.of(context).primaryColor,
                                        SizeFont.h3.size),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: MyTextStyle.lotName(
                                  "Combien y a-t-il d'étage :",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: CustomTextFieldWidget(
                                      keyboardType: TextInputType.number,
                                      controller: etageController,
                                      isEditable: true,
                                      onChanged: (val) {
                                        int? numberOfFloors =
                                            int.tryParse(val.trim());

                                        setState(() {
                                          building.etage ??= [];
                                          // Retirer les anciens étages "RDC" et "étage X"
                                          building.etage!.removeWhere(
                                              (element) =>
                                                  element == "RDC" ||
                                                  element.startsWith("étage "));

                                          if (numberOfFloors != null &&
                                              numberOfFloors >= 0) {
                                            if (numberOfFloors >= 1) {
                                              building.etage!.add("RDC");
                                            }
                                            for (int i = 1;
                                                i < numberOfFloors;
                                                i++) {
                                              building.etage!.add("étage $i");
                                            }
                                          } else {
                                            // Si la valeur n'est pas un nombre valide, ou 0, réinitialise avec juste "RDC"
                                            if (building.etage!.isEmpty &&
                                                (numberOfFloors == null ||
                                                    numberOfFloors == 0)) {
                                              building.etage = ["RDC"];
                                            }
                                          }
                                        });
                                      }),
                                ),
                              ),
                            ],
                          ),
                          MyTextStyle.postDesc(
                              "Pour un bâtiment composé d'un RDC+2 étages, veuillez noter 3",
                              SizeFont.para.size,
                              Colors.black54,
                              fontweight: FontWeight.normal,
                              textAlign: TextAlign.justify),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                width: width / 1.5,
                                child: MyTextStyle.lotName(
                                  "Cette structure a-t-elle un souterrain ?",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  thumbIcon: thumbIcon,
                                  value: building.hasUnderground,
                                  onChanged: (bool value) {
                                    setState(() {
                                      building.hasUnderground = value;
                                      if (!value) {
                                        // Si hasUnderground devient false, retire les sous-sols de la liste 'etage'
                                        building.etage?.removeWhere((element) =>
                                            element.startsWith("Sous-sol"));
                                        undergroundLevelController.clear();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Visibility(
                            visible: building.hasUnderground,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: MyTextStyle.lotName(
                                        "Combien y a-t-il de niveau :",
                                        Colors.black87,
                                        SizeFont.h3.size,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: CustomTextFieldWidget(
                                          keyboardType: TextInputType.number,
                                          controller:
                                              undergroundLevelController,
                                          isEditable: true,
                                          onChanged: (val) {
                                            int? numberOfUndergroundLevels =
                                                int.tryParse(val.trim());

                                            setState(() {
                                              building.etage ??= [];
                                              // Retirer les anciens sous-sols
                                              building.etage!.removeWhere(
                                                  (element) => element
                                                      .startsWith("Sous-sol"));

                                              if (numberOfUndergroundLevels !=
                                                      null &&
                                                  numberOfUndergroundLevels >=
                                                      0) {
                                                for (int i = 1;
                                                    i <=
                                                        numberOfUndergroundLevels;
                                                    i++) {
                                                  building.etage!
                                                      .add("Sous-sol -$i");
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          MyTextStyle.postDesc(
                              "Pour un souterrain composé de 2 niveaux, veuillez noter 2",
                              SizeFont.para.size,
                              Colors.black54,
                              fontweight: FontWeight.normal,
                              textAlign: TextAlign.justify),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                width: width / 1.5,
                                child: MyTextStyle.lotName(
                                  "Cette structure a-t-elle un syndic différent ?",
                                  Colors.black87,
                                  SizeFont.h3.size,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  thumbIcon: thumbIcon,
                                  value: building.hasDifferentSyndic,
                                  onChanged: (bool value) {
                                    setState(() {
                                      building.hasDifferentSyndic = value;
                                      if (!value) {
                                        _lookupController.clear();
                                        building.syndicAgency = null;
                                        building.geranceRef = null;
                                        searchResults = [];
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          buildAgencySearchSection(
                            visible: building.hasDifferentSyndic,
                            isSearching: isSearching,
                            searchResults: searchResults,
                            controller: agencySearchController,
                            onSelect: (Agency agency) {
                              setState(() {
                                agencySearchController.text = agency.name;
                                _itemSelected = true;
                                searchResults = [];
                                building.syndicAgency = agency; // cache d'affichage
                                building.geranceRef = _flow.refFor(agency);

                                agents = [];
                                selectedAgent = null;
                              });
                            },
                            onChanged: (String val) {
                              if (val.isEmpty) {
                                setState(() {
                                  searchResults = [];
                                  isSearching = false;
                                  _itemSelected = false;
                                  building.syndicAgency = null;
                                  building.geranceRef = null;
                                });
                              } else {
                                searchAgencyByEmail(val, building);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _remove("la structure", index, building.id),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
                  const SizedBox(height: 10),
                  Center(
                    child: ButtonAdd(
                      color: Colors.transparent,
                      icon: Icons.add,
                      text: "Ajouter une structure",
                      size: SizeFont.h3.size,
                      horizontal: 20,
                      vertical: 10,
                      colorText: widget.color,
                      borderColor: Colors.transparent,
                      function: addBuilding,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Center(
                child: ButtonAdd(
                  color: widget.color,
                  icon: Icons.save,
                  text: "Enregistrer",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: Colors.white,
                  borderColor: Colors.transparent,
                  function: saveBuildings,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remove(String object, int index, String? structureId) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => removeBuilding(index, structureId),
        icon: const Icon(Icons.delete_forever, color: Colors.black54),
        label: MyTextStyle.postDesc(
          "Supprimer $object",
          SizeFont.h3.size,
          Colors.black54,
        ),
      ),
    );
  }
}
