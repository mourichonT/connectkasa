import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';
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
import 'package:flutter/services.dart'; // Gardez cette importation si elle est utilisée ailleurs

// Note: Vous devrez mettre à jour votre fichier 'structure_residence.dart'
// pour inclure les nouvelles propriétés 'hasUnderground', 'hasDifferentSyndic', et 'syndicAgency'.
// Voir la section "Mettez à jour votre modèle StructureResidence" ci-dessous.

class ManageStructure extends StatefulWidget {
  final Residence residence;
  final Color color;

  ManageStructure({super.key, required this.residence, required this.color});

  @override
  State<ManageStructure> createState() => ManageStructureState();
}

class ManageStructureState extends State<ManageStructure> {
  final DatabasesAgencyServices _agencyServices = DatabasesAgencyServices();
  final DataBasesResidenceServices _residenceServices =
      DataBasesResidenceServices(); // Nouvelle instance du service
  List<Agent> agents = [];
  List<StructureResidence> buildings = [];
  List<Agency> searchResults = [];
  Agent? selectedAgent;
  String buildingType = "";

  bool isSearching = false;
  List<String> itemsElements = [];
  bool _itemSelected = false;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Contrôleur pour le champ de recherche d'agence
  final TextEditingController _lookupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBuildings(); // Appel pour charger les structures existantes
    _lookupController.addListener(() {
      final text = _lookupController.text.toLowerCase();
      if (text.isEmpty) {
        setState(() {
          searchResults = [];
          isSearching = false;
          _itemSelected = false;
        });
      } else {
        searchAgencyByEmail(text);
      }
    });
    itemsElements = ElementsList.elements();
  }

  // Fonction asynchrone pour charger les structures depuis Firestore
  Future<void> _loadBuildings() async {
    if (widget.residence.id != null) {
      // Récupère les structures en utilisant la nouvelle fonction du service
      final fetchedBuildings = await _residenceServices
          .getStructuresByResidence(widget.residence.id!);
      // S'assure que toutes les cartes sont fermées lors du chargement
      for (var building in fetchedBuildings) {
        building.isExpanded = false;
      }
      setState(() {
        buildings = fetchedBuildings;
      });
    } else {
      buildings =
          []; // Si pas d'ID de résidence, initialise la liste comme vide
    }
  }

  Future<void> searchAgencyByEmail(String emailPart) async {
    setState(() {
      isSearching = true;
    });

    final results = await _agencyServices.searchAgencyByEmail(emailPart);

    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  void addBuilding() {
    setState(() {
      // Un nouveau bâtiment est ajouté, par défaut isExpanded = true
      buildings.add(StructureResidence(
          name: '',
          type: '',
          isExpanded: true)); // Ajout de isExpanded pour le nouvel élément
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
    _controllers['building_ref_gerance_$index']
        ?.dispose(); // Correction du nom de la clé
    _focusNodes['building_ref_gerance_$index']
        ?.dispose(); // Correction du nom de la clé
  }

  void removeBuilding(int index, String? structureId) async {
    // Made structureId nullable
    setState(() {
      disposeControllerForBuilding(
          index); // Utiliser la fonction pour un bâtiment spécifique
      buildings.removeAt(index);
    });
    if (structureId != null) {
      // Only attempt to remove from DB if structureId exists
      await _residenceServices.removeStructure(
          widget.residence.id!, structureId);
    }
  }

  // MODIFICATION MAJEURE ICI
  Future<void> saveBuildings() async {
    // Supprimer l'argument 'index'
    if (widget.residence.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Impossible de sauvegarder : ID de résidence manquant.")),
      );
      return;
    }

    try {
      for (var building in buildings) {
        print(building.toJson());
        // Assurez-vous que votre service 'DataBasesResidenceServices' a une méthode pour sauvegarder ou mettre à jour une structure.
        // Par exemple, vous pouvez avoir une méthode 'addOrUpdateStructure' qui gère la création et la mise à jour.
        await _residenceServices.saveStructure(widget.residence.id!,
            building); // Utilisez la fonction de sauvegarde appropriée
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Structures mises à jour avec succès")),
      );

      // Optionnel: Replier tous les bâtiments après sauvegarde et recharger pour s'assurer que les IDs sont à jour si nécessaire
      setState(() {
        for (var building in buildings) {
          building.isExpanded = false;
        }
      });
      _loadBuildings(); // Recharger les bâtiments pour obtenir les IDs Firestore si de nouveaux ont été ajoutés
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
    _lookupController.dispose(); // Disposez du contrôleur de recherche
    super.dispose();
  }

  // Fonction utilitaire pour initialiser et récupérer un TextEditingController et son FocusNode
  TextEditingController _initAndGetController(String key, String? initialText) {
    _controllers.putIfAbsent(key, () => TextEditingController());
    _controllers[key]!.text = initialText ?? '';
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
      body: SingleChildScrollView(
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
            // Utilisation de .toList() pour s'assurer que la liste est construite avant d'être utilisée
            ...buildings.asMap().entries.map((entry) {
              final index = entry.key;
              final building = entry.value;

              // Utilisation de la fonction utilitaire pour initialiser les contrôleurs
              final nameController =
                  _initAndGetController('building_name_$index', building.name);
              final elementsController = _initAndGetController(
                  'building_elements_$index', building.elements?.join(', '));
              final etageController = _initAndGetController(
                  'building_etage_$index', building.etage?.length.toString());
              final undergroundLevelController = _initAndGetController(
                  'building_undergroundLevel_$index',
                  building.undergroundLevel?.length.toString());
              // Contrôleur pour le champ de référence de gérance spécifique à chaque bâtiment
              final refGeranceController = _initAndGetController(
                  'building_ref_gerance_$index', building.refGerance);

              return Card(
                // Ajoute une carte pour l'effet "portefeuille"
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                // CORRECTION CLÉ 2: Utiliser ObjectKey pour une clé stable basée sur l'identité de l'objet.
                // Cela résout l'erreur "A GlobalKey was used multiple times".
                child: ExpansionTile(
                  key: ObjectKey(building),
                  initiallyExpanded: building.isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      building.isExpanded = expanded;
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
                              // Affiche le type et le nom du bâtiment
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
                          // Les champs de nom et de type sont maintenant dans le titre de l'ExpansionTile
                          // Si vous voulez aussi les afficher quand la tuile est dépliée pour modification:
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
                            building
                                .type, // Utilise la propriété 'type' du bâtiment
                            false,
                            items: ElementsList.structureType(),
                            onValueChanged: (value) {
                              setState(() {
                                building.type =
                                    value!; // Met à jour la propriété 'type' du bâtiment
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
                                        building.elements!.add(itemsElement);
                                      } else {
                                        building.elements!.remove(itemsElement);
                                      }
                                      elementsController.text =
                                          building.elements!.join(', ');
                                    });
                                  },
                                  backgroundColor: const Color(0xFFF5F6F9),
                                  selectedColor: Theme.of(context).primaryColor,
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
                                        // Tente de convertir la valeur en un entier
                                        int? numberOfFloors =
                                            int.tryParse(val.trim());

                                        if (numberOfFloors != null &&
                                            numberOfFloors >= 0) {
                                          List<String> floors = [];
                                          // Crée une liste pour stocker les noms des étages

                                          // Ajoute le "RDC" si le nombre d'étages est supérieur ou égal à 1
                                          if (numberOfFloors >= 1) {
                                            floors.add("RDC");
                                          }

                                          // Ajoute les étages numérotés (étage1, étage2, ...)
                                          for (int i = 1;
                                              i < numberOfFloors;
                                              i++) {
                                            floors.add("étage $i");
                                          }
                                          // Assurez-vous que l'étage est null si le nombre est 0 ou non valide, ou si on veut une liste vide
                                          if (numberOfFloors == 0) {
                                            building.etage = [
                                              "RDC"
                                            ]; // Ou null si vous préférez un champ vide
                                          } else {
                                            building.etage = floors;
                                          }
                                        } else {
                                          // Si la valeur n'est pas un nombre valide, vide la liste des étages
                                          building.etage = ["RDC"];
                                        }
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
                                        building.undergroundLevel = null;
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

                                            if (numberOfUndergroundLevels !=
                                                    null &&
                                                numberOfUndergroundLevels >=
                                                    0) {
                                              List<String> levels = [];
                                              for (int i = 1;
                                                  i <=
                                                      numberOfUndergroundLevels;
                                                  i++) {
                                                levels.add("Sous-sol -$i");
                                              }
                                              building.undergroundLevel =
                                                  levels;
                                            } else {
                                              building.undergroundLevel = [];
                                            }
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
                              "Pour un souterrain composé de 2 niveaux en souterrain, veuillez noter 2",
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
                                        _lookupController
                                            .clear(); // Utilisez le contrôleur dédié
                                        building.syndicAgency = null;
                                        building.refGerance = null;
                                        searchResults = [];
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Visibility(
                            visible: building.hasDifferentSyndic,
                            child: Column(
                              children: [
                                CustomTextFieldWidget(
                                  label: "Mail de l'agence",
                                  controller:
                                      _lookupController, // Utilisez le contrôleur dédié
                                  isEditable: true,
                                  // onChanged: (val) =>
                                  //     building.refGerance = val
                                ),
                                const SizedBox(height: 10),
                                //Uncomment and adapt this part if you intend to use it for searching agencies
                                AgencySearchResultList(
                                  isSearching: isSearching,
                                  searchResults: searchResults,
                                  onSelect: (agency) {
                                    setState(() {
                                      _lookupController.text = agency
                                          .name; // Use the dedicated controller
                                      _itemSelected = true;
                                      searchResults = [];
                                      building.syndicAgency = agency;

                                      // _controllers["agencyName"]!.text = agency.name; // This line seems superfluous or incorrect here
                                      agents = [];
                                      selectedAgent = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Pass `building.id` directly, which can be null for new buildings
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
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 40),
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
                  function: saveBuildings, // Appel sans les parenthèses
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remove(String object, int index, String? structureId) {
    // Made structureId nullable here
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
