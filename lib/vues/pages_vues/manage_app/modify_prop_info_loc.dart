import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/search_agency_module.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/statut_list.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModifyPropInfoLoc extends StatefulWidget {
  final Lot lot;
  final String refLotSelected;
  final String uid;

  const ModifyPropInfoLoc({
    super.key,
    required this.lot,
    required this.uid,
    required this.refLotSelected,
  });

  @override
  State<StatefulWidget> createState() => ModifyPropInfoLocState();
}

class ModifyPropInfoLocState extends State<ModifyPropInfoLoc> {
  DataBasesLotServices lotServices = DataBasesLotServices();

  //TextEditingController nameSyndic = TextEditingController();
  String? selectedStatut;
  bool isProprietaire = false;
  bool isSearching = false;
  List<Agency> searchResults = [];
  bool _itemSelected = false;
  final DatabasesAgencyServices _agencyServices = DatabasesAgencyServices();

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );
  FocusNode nameSyndicFocusNode = FocusNode();
  bool delegated = false;

  void updateBool(bool delegatedBool) {
    setState(() {
      delegated = delegatedBool;
    });
  }

  @override
  void initState() {
    super.initState();
    _initFields();
    isProprietaire = widget.lot.idProprietaire?.contains(widget.uid) ?? false;
    nameSyndicFocusNode.addListener(() => setState(() {}));
    //nameSyndic.addListener(_handleTextChange);
    _loadProperty();
  }

  void _initFields() {
    final fields = [
      // Résidence
      "mail_contact",
      "name",

      // Agence
      "agencyName",
      "agenceNumero",
      "agenceVoie",
      "agenceStreet",
      "agenceZipCodeVille",
      "agenceZipCode",
      "agenceCity",
      // Affichage combiné + divers
      "address",
      "zipCodeVille",
      "phone",
      "selectedAgent",
    ];

    for (var field in fields) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    nameSyndicFocusNode.dispose();
    //nameSyndic.removeListener(_handleTextChange);
    //nameSyndic.dispose();
    super.dispose();
  }

  TextEditingController _initAndGetController(String key, String? initialText) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialText ?? '');
    }
    _focusNodes.putIfAbsent(key, () => FocusNode());
    return _controllers[key]!;
  }

  void disposeControllerForBuilding(int index) {
    _controllers['building_name_$index']?.dispose();
    _focusNodes['building_name_$index']?.dispose();
    _controllers['agency_search_controller_$index']?.dispose();
    _focusNodes['agency_search_controller_$index']?.dispose();
  }

  Future<void> _searchAgencyByEmail(String emailPart) async {
    setState(() => isSearching = true);

    final results =
        await _agencyServices.searchAgencyByEmail('geranceLocative', emailPart);

    setState(() {
      if (results.isEmpty) {
        // Agence par défaut si aucune trouvée
        final newAgency = Agency(
          id: '',
          name: emailPart,
          city: '',
          numeros: '',
          street: '',
          voie: '',
          zipCode: '',
          syndic: AgencyDept(
            agents: [],
            mail: emailPart,
            phone: '',
          ),
        );
        searchResults = [newAgency];
        widget.lot.syndicAgency = newAgency;
        _itemSelected = true;

        // Remplir les contrôleurs dérivés
        _controllers["agencyName"]!.text = newAgency.name;
        _controllers["agenceNumero"]!.text = newAgency.numeros;
        _controllers["agenceVoie"]!.text = newAgency.voie;
        _controllers["agenceStreet"]!.text = newAgency.street;
        _controllers["agenceZipCode"]!.text = newAgency.zipCode;
        _controllers["agenceCity"]!.text = newAgency.city;
        _controllers["address"]!.text =
            "${newAgency.numeros} ${newAgency.voie} ${newAgency.street}".trim();
        _controllers["zipCodeVille"]!.text =
            "${newAgency.zipCode} ${newAgency.city}".trim();
      } else {
        searchResults = results;
        _itemSelected =
            false; // l’utilisateur doit choisir un élément dans la liste
      }
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Ma gestion locative",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildDropDownMenu(width, 'Statut'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: width / 1.5,
                  child: MyTextStyle.annonceDesc(
                      "Souhaitez-vous déléguer la gestion de votre bien ",
                      SizeFont.h3.size,
                      2),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    thumbIcon: thumbIcon,
                    value: delegated,
                    onChanged: (bool value) async {
                      setState(() {
                        delegated = value;
                        updateBool(delegated);
                      });

                      if (!delegated) {
                        // Suppression immédiate du champ en base
                        final ok = await lotServices.updateLot(
                          widget.lot.residenceId,
                          widget.lot.refLot,
                          'syndicAgency',
                          FieldValue.delete(),
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? "L'agence de gestion a été supprimée"
                                  : "Erreur lors de la suppression de l'agence"),
                            ),
                          );
                        }

                        // Vider aussi les contrôleurs locaux pour éviter affichage résiduel
                        for (final k in [
                          "agencyName",
                          "agenceNumero",
                          "agenceVoie",
                          "agenceStreet",
                          "agenceZipCode",
                          "agenceCity",
                          "address",
                          "zipCodeVille",
                          "mail_contact",
                        ]) {
                          _controllers[k]!.clear();
                        }
                        widget.lot.syndicAgency = null;
                      }
                    },
                  ),
                ),
              ],
            ),
            if (delegated) ...[
              buildAgencySearchSection(
                visible: delegated,
                isSearching: isSearching,
                searchResults: searchResults,
                controller: _controllers["mail_contact"]!,
                onSelect: (Agency agency) {
                  setState(() {
                    // Agence choisie
                    widget.lot.syndicAgency = agency;
                    _itemSelected = true;
                    searchResults.clear();
                    _controllers["agencyName"]!.text = agency.name;
                    _controllers["agenceNumero"]!.text =
                        agency.numeros; // <-- fix
                    _controllers["agenceVoie"]!.text = agency.voie;
                    _controllers["agenceStreet"]!.text = agency.street;
                    _controllers["agenceZipCode"]!.text = agency.zipCode;
                    _controllers["agenceCity"]!.text = agency.city;
                    _controllers["mail_contact"]!.text =
                        agency.syndic?.mail ?? "";
                    _controllers["address"]!.text =
                        "${agency.numeros} ${agency.voie} ${agency.street}"
                            .trim();
                    _controllers["zipCodeVille"]!.text =
                        "${agency.zipCode} ${agency.city}".trim();
                  });
                },
                onChanged: (String val) async {
                  if (val.isEmpty) {
                    setState(() {
                      searchResults.clear();
                      isSearching = false;
                      _itemSelected = false;
                      widget.lot.syndicAgency = null;
                      // vider affichage agence
                      for (final k in [
                        "agencyName",
                        "agenceNumero",
                        "agenceVoie",
                        "agenceStreet",
                        "agenceZipCode",
                        "agenceCity",
                        "address",
                        "zipCodeVille",
                      ]) {
                        _controllers[k]!.clear();
                      }
                    });
                  } else {
                    await _searchAgencyByEmail(val);
                  }
                },
              ),
              const SizedBox(height: 12),
              if (delegated &&
                  _controllers["mail_contact"]!.text.isNotEmpty) ...[
                if (_itemSelected &&
                    widget.lot.syndicAgency != null &&
                    searchResults
                        .any((a) => a.id == widget.lot.syndicAgency!.id))
                  // Mail trouvé dans la liste → champs non éditables
                  ...[
                  buildField("Nom de l'agence", "agencyName", editable: false),
                  buildField("Adresse", "address", editable: false),
                  buildField("Code Postal Ville", "zipCodeVille",
                      editable: false),
                ] else
                  // Mail non trouvé dans la liste → champs éditables
                  ...[
                  buildField("Nom de l'agence", "agencyName", editable: true),
                  Row(
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: buildField("Numéro", "agenceNumero",
                            editable: true),
                      )),
                      Expanded(
                          child:
                              buildField("Voie", "agenceVoie", editable: true)),
                    ],
                  ),
                  buildField("Libelé", "agenceStreet", editable: true),
                  Row(
                    children: [
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: buildField("Code Postal", "agenceZipCode",
                            editable: true),
                      )),
                      Expanded(
                          child: buildField("Ville", "agenceCity",
                              editable: true)),
                    ],
                  ),
                ],
              ]
            ],
            const SizedBox(
              height: 80,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ButtonAdd(
                icon: Icons.save,
                text: "Enregistrer",
                color: Theme.of(context).primaryColor,
                horizontal: 20,
                vertical: 10,
                size: SizeFont.h3.size,
                function: savePreferenceRent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropDownMenu(double width, String label) {
    List<String> statuts = ImmoList.statutList();
    bool isEnabled = !widget.lot.idLocataire!.contains(widget.uid);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w400,
              fontSize: SizeFont.h3.size),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
        ),
        value: selectedStatut,
        items: statuts.map((statut) {
          return DropdownMenuItem(
            value: statut, // Assurez-vous que chaque valeur est unique
            child: Text(
              statut,
              style: TextStyle(
                  color: isEnabled ? Colors.black87 : Colors.black54,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeFont.h3.size),
            ),
          );
        }).toList(),
        onChanged: isEnabled
            ? (newValue) {
                setState(() {
                  selectedStatut = newValue as String?;
                  widget.lot.type = selectedStatut!;
                });
              }
            : null,
        isExpanded: true,
        style: TextStyle(
            color: isEnabled ? Colors.black54 : Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: SizeFont.h3.size),
        disabledHint: Text(
          selectedStatut ?? '',
          style: TextStyle(
              color: isEnabled ? Colors.black54 : Colors.black87,
              fontWeight: FontWeight.w400,
              fontSize: SizeFont.h3.size),
        ),
      ),
    );
  }

  Widget buildField(String label, String field, {bool editable = true}) {
    return CustomTextFieldWidget(
      label: label,
      field: field,
      controller: _controllers[field],
      focusNode: _focusNodes[field],
      isEditable: editable,
      value: editable ? null : _controllers[field]?.text,
      onSubmit: (lbl, fld, val) async {
        await savePreferenceRent();
      },
      refresh: () => setState(() {}),
    );
  }

  // Future<void> _updateField(String field, String label, String value) async {
  //   final success = await lotServices.updateLot(
  //       widget.lot.residenceId, widget.lot.refLot, field, value);

  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(success
  //             ? "$label mis à jour"
  //             : "Erreur lors de la mise à jour de $label"),
  //       ),
  //     );
  //   }
  // }
  void _loadProperty() {
    selectedStatut = widget.lot.type;
    delegated = widget.lot.syndicAgency != null;

    final agency = widget.lot.syndicAgency;

    _controllers["agencyName"]?.text = agency?.name ?? '';
    _controllers["agenceNumero"]?.text = agency?.numeros ?? '';
    _controllers["agenceVoie"]?.text = agency?.voie ?? '';
    _controllers["agenceStreet"]?.text = agency?.street ?? '';
    _controllers["agenceZipCode"]?.text = agency?.zipCode ?? '';
    _controllers["agenceCity"]?.text = agency?.city ?? '';
    _controllers["mail_contact"]?.text = agency?.syndic?.mail ?? '';

    setState(() {});
  }

  Future<void> savePreferenceRent() async {
    final String mailContact = _controllers["mail_contact"]?.text.trim() ?? '';

    if (!delegated && mailContact.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Veuillez remplir le mail de contact ou celui de l'agence"),
        ),
      );
      return;
    }

    final Map<String, dynamic> updatedData = {
      'type': selectedStatut,
    };

    if (delegated && mailContact.isNotEmpty) {
      // ✅ Toujours construire l'agence à partir des champs
      final selectedAgency = Agency(
        id: widget.lot.syndicAgency?.id ?? '',
        name: _controllers["agencyName"]!.text,
        numeros: _controllers["agenceNumero"]!.text,
        voie: _controllers["agenceVoie"]!.text,
        street: _controllers["agenceStreet"]!.text,
        zipCode: _controllers["agenceZipCode"]!.text,
        city: _controllers["agenceCity"]!.text,
        syndic: AgencyDept(
          agents: widget.lot.syndicAgency?.syndic?.agents ?? [],
          mail: _controllers["mail_contact"]!.text,
          phone: widget.lot.syndicAgency?.syndic?.phone ?? '',
        ),
      );

      widget.lot.syndicAgency = selectedAgency;
      updatedData['syndicAgency'] = selectedAgency.toJson();
    } else {
      updatedData['syndicAgency'] = null;
    }

    bool success = true;

    // 🔁 Mise à jour champ par champ
    for (final entry in updatedData.entries) {
      final ok = await lotServices.updateLot(
        widget.lot.residenceId,
        widget.lot.refLot,
        entry.key,
        entry.value,
      );
      if (!ok) success = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "Résidence mise à jour avec succès"
              : "Erreur lors de la mise à jour"),
        ),
      );
    }
  }
}
