import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';
import 'package:connect_kasa/models/enum/elements_list.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';
import 'package:connect_kasa/vues/widget_view/components/agency_search_result_list.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageStructure extends StatefulWidget {
  final Residence residence;
  final Color color;

  ManageStructure({super.key, required this.residence, required this.color});

  @override
  State<ManageStructure> createState() => ManageStructureState();
}

class ManageStructureState extends State<ManageStructure> {
  final DatabasesAgencyServices _agencyServices = DatabasesAgencyServices();
  List<Agent> agents = [];
  List<StructureResidence> buildings = [];
  List<Agency> searchResults = [];
  Agent? selectedAgent;

  // Booléen pour le switch "syndic différent"
  bool hasDifferentSyndic = false;
  bool underground = false;

  // Booléen pour état de recherche
  bool isSearching = false;
  List<String> filters = [];
  List<String> itemsElements = [];
  bool _itemSelected = false;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    buildings = [];
    _initFields();
    itemsElements = ElementsList.elements();
  }

  void _initFields() {
    final fields = [
      "agencyName",
      "nameAgent",
      "surnameAgent",
      "lookup",
      "selectedAgent",
    ];

    for (var field in fields) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
    }

    // Listener sur le champ "lookup" pour lancer la recherche
    _controllers["lookup"]!.addListener(() {
      final text = _controllers["lookup"]!.text.toLowerCase();
      if (text.isEmpty) {
        setState(() {
          searchResults = [];
          isSearching = false;
        });
      } else {
        searchAgencyByEmail(text);
      }
    });
  }

  Future<void> searchAgencyByEmail(String emailPart) async {
    setState(() {
      isSearching = true;
    });

    // Simuler un appel réseau (remplace par ton service réel)
    final results = await _agencyServices.searchAgencyByEmail(emailPart);

    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  // Exemple simulé, remplace par ton _agencyServices.searchAgencyByEmail

  void addBuilding() {
    setState(() {
      buildings.add(StructureResidence(name: '', type: ''));
    });
  }

  void removeBuilding(int index) {
    setState(() {
      buildings.removeAt(index);
    });
  }

  void saveBuildings() {
    for (var building in buildings) {
      print(building.toJson());
      // Envoi vers Firestore si nécessaire
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Structure mis à jour avec succès")),
    );
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
    // Dispose des controllers et focus nodes
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, focusNode) => focusNode.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Gestion de la structure",
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
            MyTextStyle.lotName("Structure", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 20),
            ...buildings.asMap().entries.map((entry) {
              final index = entry.key;
              final building = entry.value;

              // Initialiser contrôleurs dynamiques pour éviter recréation à chaque build
              if (!_controllers.containsKey('building_name_$index')) {
                _controllers['building_name_$index'] =
                    TextEditingController(text: building.name);
              }
              if (!_controllers.containsKey('building_elements_$index')) {
                _controllers['building_elements_$index'] =
                    TextEditingController(
                        text: building.elements?.join(', ') ?? '');
              }
              if (!_controllers.containsKey('building_etage_$index')) {
                _controllers['building_etage_$index'] = TextEditingController(
                    text: building.etage?.join(', ') ?? '');
              }
              if (!_controllers
                  .containsKey('building_undergroundLevel_$index')) {
                _controllers['building_undergroundLevel_$index'] =
                    TextEditingController(
                        text: building.etage?.join(', ') ?? '');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: CustomTextFieldWidget(
                            label: "Nom",
                            controller: _controllers['building_name_$index']!,
                            isEditable: true,
                            onChanged: (val) => building.name = val,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: MyDropDownMenu(
                            height: 90,
                            width,
                            "Type de structure",
                            "",
                            false,
                            items: ElementsList.structureType(),
                            onValueChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        width: width / 1.5,
                        child: MyTextStyle.annonceDesc(
                          "Cette structure a-t-elle un syndic différent ?",
                          SizeFont.h3.size,
                          2,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          thumbIcon: thumbIcon,
                          value: hasDifferentSyndic,
                          onChanged: (bool value) {
                            setState(() {
                              hasDifferentSyndic = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: hasDifferentSyndic,
                    child: Column(
                      children: [
                        CustomTextFieldWidget(
                          label: "Recherche agence",
                          controller: _controllers["lookup"],
                          isEditable: true,
                        ),
                        const SizedBox(height: 10),
                        AgencySearchResultList(
                          isSearching: isSearching,
                          searchResults: searchResults,
                          onSelect: (agency) {
                            setState(() {
                              _controllers["lookup"]!.text = agency.name;
                              _itemSelected = true;
                              searchResults = [];
                              _controllers["agencyName"]!.text = agency.name;

                              agents = [];
                              selectedAgent = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
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
                      children: itemsElements.map((String itemsElement) {
                        return FilterChip(
                          label: MyTextStyle.lotDesc(
                              itemsElement, SizeFont.h3.size),
                          selected: filters.contains(itemsElement),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                filters.add(itemsElement);
                              } else {
                                filters.remove(itemsElement);
                              }
                            });
                          },
                          backgroundColor: Color(
                              0xFFF5F6F9), // couleur de fond quand non sélectionné
                          selectedColor: Theme.of(context)
                              .primaryColor, // couleur quand sélectionné
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // angle arrondi
                          ),
                          side: BorderSide(
                            color: filters.contains(itemsElement)
                                ? Theme.of(context).primaryColor
                                : Color(0xFFF5F6F9), // couleur de la bordure
                            width: 2, // épaisseur de la bordure
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
                            controller: _controllers['building_etage_$index']!,
                            isEditable: true,
                            onChanged: (val) => building.etage =
                                val.split(',').map((e) => e.trim()).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  MyTextStyle.annonceDesc(
                    "Pour un batiment composé d'un RDC+2 étages, veuillez noter 3",
                    SizeFont.h3.size,
                    2,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        width: width / 1.5,
                        child: MyTextStyle.annonceDesc(
                          "Cette structure a-t-elle un souterrain ?",
                          SizeFont.h3.size,
                          2,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          thumbIcon: thumbIcon,
                          value: underground,
                          onChanged: (bool value) {
                            setState(() {
                              underground = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: underground,
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
                                padding: const EdgeInsets.only(left: 10),
                                child: CustomTextFieldWidget(
                                  keyboardType: TextInputType.number,
                                  controller: _controllers[
                                      'building_undergroundLevel_$index']!,
                                  isEditable: true,
                                  onChanged: (val) => building.etage = val
                                      .split(',')
                                      .map((e) => e.trim())
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        MyTextStyle.annonceDesc(
                          "Pour un sousterain composé de 2 niveaux en souterrain, veuillez noter 2",
                          SizeFont.h3.size,
                          2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _remove("le bâtiment", index),
                  const SizedBox(height: 15),
                ],
              );
            }).toList(),
            Center(
              child: ButtonAdd(
                color: Colors.transparent,
                icon: Icons.add,
                text: "Ajouter un bâtiment",
                size: SizeFont.h3.size,
                horizontal: 20,
                vertical: 10,
                colorText: widget.color,
                borderColor: Colors.transparent,
                function: addBuilding,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _remove(String object, int index) {
    return Center(
      child: TextButton.icon(
        onPressed: () => removeBuilding(index),
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
