import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/agency_search_flow.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/search_agency_module.dart';
import 'package:konodal/core/providers/agency_search_flow_provider.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/core/repositories/lot_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/statut_list.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/agency_dept.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModifyPropInfoLoc extends ConsumerStatefulWidget {
  final Lot lot;
  final String idLotSelected;
  final String uid;

  const ModifyPropInfoLoc({
    super.key,
    required this.lot,
    required this.uid,
    required this.idLotSelected,
  });

  @override
  ConsumerState<ModifyPropInfoLoc> createState() => ModifyPropInfoLocState();
}

class ModifyPropInfoLocState extends ConsumerState<ModifyPropInfoLoc> {
  late final ILotRepository lotServices;

  //TextEditingController nameSyndic = TextEditingController();
  String? selectedStatut;
  bool isProprietaire = false;
  bool isSearching = false;
  List<Agency> searchResults = [];
  late final AgencySearchFlow _flow;

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
    lotServices = ref.read(lotRepositoryProvider);
    _flow = ref.read(agencySearchFlowProvider('geranceLocative'));
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

  void disposeControllerForBuilding(int index) {
    _controllers['building_name_$index']?.dispose();
    _focusNodes['building_name_$index']?.dispose();
    _controllers['agency_search_controller_$index']?.dispose();
    _focusNodes['agency_search_controller_$index']?.dispose();
  }

  Future<void> _searchAgencyByEmail(String emailPart) async {
    setState(() => isSearching = true);

    final results = await _flow.search(emailPart);

    setState(() {
      if (results.isEmpty) {
        // Aucun match dans gerances : entrée custom, non référencée.
        final newAgency = _flow.buildCustomAgency(emailPart);
        searchResults = [newAgency];
        widget.lot.syndicAgency = newAgency;
        widget.lot.geranceRef = null;

        // Remplir les contrôleurs dérivés
        _controllers["agencyName"]!.text = newAgency.name;
        _controllers["agenceStreet"]!.text = newAgency.street;
        _controllers["agenceZipCode"]!.text = newAgency.zipCode;
        _controllers["agenceCity"]!.text = newAgency.city;
        _controllers["address"]!.text = newAgency.street;
        _controllers["zipCodeVille"]!.text =
            "${newAgency.zipCode} ${newAgency.city}".trim();
      } else {
        searchResults = results; // l’utilisateur doit choisir un élément dans la liste
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
                        // Suppression immédiate des deux champs en base
                        // (référence ou copie custom, selon ce qui était actif)
                        final okAgency = await lotServices
                            .updateLot(
                              widget.lot.residenceId,
                              widget.lot.id!,
                              'syndicAgency',
                              FieldValue.delete(),
                            )
                            .then((result) => result.when(
                                success: (v) => v, failure: (_) => false));
                        final okRef = await lotServices
                            .updateLot(
                              widget.lot.residenceId,
                              widget.lot.id!,
                              'geranceRef',
                              FieldValue.delete(),
                            )
                            .then((result) => result.when(
                                success: (v) => v, failure: (_) => false));
                        final ok = okAgency && okRef;

                        if (context.mounted) {
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
                        widget.lot.geranceRef = null;
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
                    // Agence choisie, référencée dans gerances
                    widget.lot.syndicAgency = agency; // cache d'affichage
                    widget.lot.geranceRef = _flow.refFor(agency);
                    searchResults.clear();
                    _controllers["agencyName"]!.text = agency.name;
                    _controllers["agenceStreet"]!.text = agency.street;
                    _controllers["agenceZipCode"]!.text = agency.zipCode;
                    _controllers["agenceCity"]!.text = agency.city;
                    _controllers["mail_contact"]!.text =
                        agency.syndic?.mail ?? "";
                    _controllers["address"]!.text = agency.street;
                    _controllers["zipCodeVille"]!.text =
                        "${agency.zipCode} ${agency.city}".trim();
                  });
                },
                onChanged: (String val) async {
                  if (val.isEmpty) {
                    setState(() {
                      searchResults.clear();
                      isSearching = false;
                      widget.lot.syndicAgency = null;
                      widget.lot.geranceRef = null;
                      // vider affichage agence
                      for (final k in [
                        "agencyName",
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
                if (widget.lot.geranceRef != null)
                  // Référencé dans gerances → champs non éditables
                  ...[
                  buildField("Nom de l'agence", "agencyName", editable: false),
                  buildField("Adresse", "address", editable: false),
                  buildField("Code Postal Ville", "zipCodeVille",
                      editable: false),
                ] else
                  // Mail non trouvé dans la liste → champs éditables
                  ...[
                  buildField("Nom de l'agence", "agencyName", editable: true),
                  buildField("Adresse", "agenceStreet", editable: true),
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
        // Défense contre une valeur absente de la liste (lot sans statut
        // renseigné, ex. donnée de test) : DropdownButtonFormField plante
        // si value ne correspond à aucun item plutôt que de l'ignorer.
        value: statuts.contains(selectedStatut) ? selectedStatut : null,
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

  Future<void> _loadProperty() async {
    selectedStatut = widget.lot.type;
    delegated = widget.lot.geranceRef != null || widget.lot.syndicAgency != null;

    // Si référencé dans gerances, on résout depuis la source à jour plutôt
    // que de se fier à une copie potentiellement figée.
    if (widget.lot.geranceRef != null) {
      widget.lot.syndicAgency = await _flow.resolve(widget.lot.geranceRef!);
    }

    final agency = widget.lot.syndicAgency;

    _controllers["agencyName"]?.text = agency?.name ?? '';
    _controllers["agenceStreet"]?.text = agency?.street ?? '';
    _controllers["agenceZipCode"]?.text = agency?.zipCode ?? '';
    _controllers["agenceCity"]?.text = agency?.city ?? '';
    _controllers["mail_contact"]?.text = agency?.syndic?.mail ?? '';
    _controllers["address"]?.text = agency?.street ?? '';
    _controllers["zipCodeVille"]?.text =
        agency == null ? '' : "${agency.zipCode} ${agency.city}".trim();

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

    if (delegated && widget.lot.geranceRef != null) {
      // Référencé dans gerances : on ne persiste que la référence, jamais de
      // copie (les champs affichés sont en lecture seule dans ce cas).
      updatedData['geranceRef'] = widget.lot.geranceRef!.toJson();
      updatedData['syndicAgency'] = FieldValue.delete();
    } else if (delegated && mailContact.isNotEmpty) {
      // Entrée custom, non référencée : on construit l'agence depuis les
      // champs (éditables dans ce cas).
      final selectedAgency = Agency(
        id: widget.lot.syndicAgency?.id ?? '',
        name: capitalizeFirstLetter(_controllers["agencyName"]!.text),
        street: capitalizeFirstLetter(_controllers["agenceStreet"]!.text),
        zipCode: _controllers["agenceZipCode"]!.text,
        city: capitalizeFirstLetter(_controllers["agenceCity"]!.text),
        codeQualite: widget.lot.syndicAgency?.codeQualite ?? '60',
        syndic: AgencyDept(
          agents: widget.lot.syndicAgency?.syndic?.agents ?? [],
          mail: _controllers["mail_contact"]!.text,
          phone: widget.lot.syndicAgency?.syndic?.phone ?? '',
        ),
      );

      widget.lot.syndicAgency = selectedAgency;
      updatedData['syndicAgency'] = selectedAgency.toJson();
      updatedData['geranceRef'] = FieldValue.delete();
    } else {
      updatedData['syndicAgency'] = FieldValue.delete();
      updatedData['geranceRef'] = FieldValue.delete();
    }

    bool success = true;

    // 🔁 Mise à jour champ par champ
    for (final entry in updatedData.entries) {
      final ok = await lotServices
          .updateLot(
            widget.lot.residenceId,
            widget.lot.id!,
            entry.key,
            entry.value,
          )
          .then((result) =>
              result.when(success: (v) => v, failure: (_) => false));
      if (!ok) success = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "le Lot a été mis à jour avec succès"
              : "Erreur lors de la mise à jour"),
        ),
      );
    }
  }
}
