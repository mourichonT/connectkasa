import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/search_agency_module.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';

class ManagementResInfoG extends StatefulWidget {
  final Residence residence;
  final Color color;

  const ManagementResInfoG({
    super.key,
    required this.residence,
    required this.color,
  });

  @override
  State<ManagementResInfoG> createState() => _ManagementResInfoGState();
}

class _ManagementResInfoGState extends State<ManagementResInfoG> {
  bool _isLoading = true;
  bool _itemSelected = false;
  bool delegated = false;

  List<Agency> searchResults = [];
  bool isSearching = false;

  final DatabasesAgencyServices _agencyServices = DatabasesAgencyServices();
  final DataBasesResidenceServices _residenceServices =
      DataBasesResidenceServices();

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initFields();
    delegated = widget.residence.syndicAgency?.name?.isNotEmpty ?? false;
    _loadResidenceData();
  }

  void _initFields() {
    final fields = [
      // Résidence
      "mail_contact",
      "name",
      "numero",
      "voie",
      "street",
      "zipCode",
      "city",
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
    _controllers.values.forEach((c) => c.dispose());
    _focusNodes.values.forEach((f) => f.dispose());
    super.dispose();
  }

  Future<void> _loadResidenceData() async {
    try {
      final r = widget.residence;

      // Pré-remplir champs Résidence
      _controllers["name"]!.text = r.name;
      _controllers["numero"]!.text = r.numero;
      _controllers["voie"]!.text = r.voie;
      _controllers["street"]!.text = r.street;
      _controllers["zipCode"]!.text = r.zipCode;
      _controllers["city"]!.text = r.city;

      // Mail de contact (si non délégué à l’ouverture)
      _controllers["mail_contact"]!.text = r.syndicAgency?.syndic?.mail ?? "";

      // Si déjà délégué → pré-remplir champs agence
      if (delegated && r.syndicAgency != null) {
        final a = r.syndicAgency!;
        _controllers["agencyName"]!.text = a.name;
        _controllers["agenceNumero"]!.text = a.numeros;
        _controllers["agenceVoie"]!.text = a.voie;
        _controllers["agenceStreet"]!.text = a.street;
        _controllers["agenceZipCode"]!.text = a.zipCode;
        _controllers["agenceCity"]!.text = a.city;

        _controllers["address"]!.text =
            "${a.numeros} ${a.voie} ${a.street}".trim();
        _controllers["zipCodeVille"]!.text = "${a.zipCode} ${a.city}".trim();
      }
    } catch (e) {
      debugPrint("Erreur _loadResidenceData: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur lors du chargement des données")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Recherche d'agence par email (via services) ---
  Future<void> _searchAgencyByEmail(String emailPart) async {
    setState(() => isSearching = true);

    final results =
        await _agencyServices.searchAgencyByEmail('serviceSyndic', emailPart);

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
        widget.residence.syndicAgency = newAgency;
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

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? const Icon(Icons.check)
        : const Icon(Icons.close),
  );

  Future<void> _updateField(String field, String label, String value) async {
    final success =
        await _residenceServices.updateField(widget.residence.id, field, value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "$label mis à jour"
              : "Erreur lors de la mise à jour de $label"),
        ),
      );
    }
  }

  Widget buildField(String label, String field, {bool editable = true}) {
    return CustomTextFieldWidget(
      label: label,
      field: field,
      controller: _controllers[field],
      focusNode: _focusNodes[field],
      isEditable: editable,
      value: editable ? null : _controllers[field]?.text,
      onSubmit: _updateField,
      refresh: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Modifier la résidence",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Champs Résidence (readonly sauf name)
            buildField("Nom de la résidence", "name"),
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: buildField("Numéro", "numero", editable: false),
                )),
                Expanded(
                    child: buildField("Type de voie", "voie", editable: false)),
              ],
            ),

            buildField("Nom de la voie", "street", editable: false),

            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: buildField("Code postal", "zipCode", editable: false),
                )),
                Expanded(child: buildField("Ville", "city", editable: false)),
              ],
            ),
            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: MyTextStyle.lotName(
                "Votre Syndic de Copropriété",
                Colors.black87,
                SizeFont.h2.size,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: width / 1.5,
                  child: MyTextStyle.annonceDesc(
                    "Souhaitez-vous déléguer la gestion de votre résidence? ",
                    SizeFont.h3.size,
                    2,
                  ),
                ),
                Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: delegated,
                      onChanged: (val) {
                        setState(() {
                          delegated = val;
                          // Vider mail de contact
                          _controllers["mail_contact"]!.clear();
                          // Vider les champs agence
                          _clearAgencyFields();
                          // Réinitialiser l'agence sélectionnée
                          _itemSelected = false;
                          widget.residence.syndicAgency = null;
                        });
                      },
                    )),
              ],
            ),
            const SizedBox(height: 20),

            // Mail de contact visible uniquement si non délégué
            if (!delegated) buildField("Mail de contact", "mail_contact"),

            // Section recherche agence + champs agence si délégué
            if (delegated) ...[
              buildAgencySearchSection(
                visible: delegated,
                isSearching: isSearching,
                searchResults: searchResults,
                controller: _controllers["mail_contact"]!,
                onSelect: (Agency agency) {
                  setState(() {
                    // Agence choisie
                    widget.residence.syndicAgency = agency;
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
                      widget.residence.syndicAgency = null;
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
                    widget.residence.syndicAgency != null &&
                    searchResults
                        .any((a) => a.id == widget.residence.syndicAgency!.id))
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
                function: saveResidence,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveResidence() async {
    FocusScope.of(context).unfocus();
    final String refResidence = widget.residence.id;

    final String residenceName = _controllers["name"]?.text.trim() ?? '';
    final String mailContact = _controllers["mail_contact"]?.text.trim() ?? '';

    // Vérification obligatoire : nom de résidence + au moins un mail
    if (residenceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez remplir le nom de la résidence")),
      );
      return;
    }

    if (!delegated && mailContact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Veuillez remplir le mail de contact ou celui de l'agence")),
      );
      return;
    }

    if (delegated &&
        (widget.residence.syndicAgency?.syndic?.mail?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Veuillez remplir le mail de contact ou celui de l'agence")),
      );
      return;
    }

    // Données de base de la résidence
    final Map<String, dynamic> updatedData = {
      'name': residenceName,
      'numero': _controllers["numero"]?.text ?? '',
      'voie': _controllers["voie"]?.text ?? '',
      'street': _controllers["street"]?.text ?? '',
      'zipCode': _controllers["zipCode"]?.text ?? '',
      'city': _controllers["city"]?.text ?? '',
      'mail_contact': !delegated
          ? mailContact
          : widget.residence.syndicAgency?.syndic?.mail ?? '',
    };

    // Gestion de l'agence si délégué
    if (delegated &&
        (widget.residence.syndicAgency?.name?.isNotEmpty ?? false)) {
      if (_itemSelected) {
        final selectedAgency = Agency(
          id: widget.residence.syndicAgency?.id ?? '',
          name: _controllers["agencyName"]!.text,
          numeros: _controllers["agenceNumero"]!.text,
          voie: _controllers["agenceVoie"]!.text,
          street: _controllers["agenceStreet"]!.text,
          zipCode: _controllers["agenceZipCode"]!.text,
          city: _controllers["agenceCity"]!.text,
          syndic: AgencyDept(
            agents: widget.residence.syndicAgency?.syndic?.agents ?? [],
            mail: _controllers["mail_contact"]!.text,
            phone: widget.residence.syndicAgency?.syndic?.phone ?? '',
          ),
        );

        widget.residence.syndicAgency = selectedAgency;
        updatedData['syndicAgency'] = selectedAgency.toJson();
      }
    } else {
      updatedData['syndicAgency'] = null;
    }

    final success =
        await _residenceServices.updateResidence(refResidence, updatedData);

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

  void _clearAgencyFields() {
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
  }
}
