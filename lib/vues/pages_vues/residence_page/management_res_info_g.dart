import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/agency_search_flow.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/search_agency_module.dart';
import 'package:connect_kasa/core/providers/agency_search_flow_provider.dart';
import 'package:connect_kasa/core/providers/residence_repository_provider.dart';
import 'package:connect_kasa/core/repositories/residence_repository.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';
import 'package:connect_kasa/vues/pages_vues/residence_page/manage_structure.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagementResInfoG extends ConsumerStatefulWidget {
  final Residence residence;
  final Color color;

  const ManagementResInfoG({
    super.key,
    required this.residence,
    required this.color,
  });

  @override
  ConsumerState<ManagementResInfoG> createState() => _ManagementResInfoGState();
}

/// Une exception au syndic principal : un bâtiment dont `hasDifferentSyndic`
/// est vrai (donc affecté indépendamment via manage_structure.dart). Calculée
/// à l'affichage à partir des structures, jamais persistée : évite un champ
/// de plus à maintenir en cohérence avec chaque structure individuelle.
class _SyndicException {
  final String structureId;
  final String structureName;
  final String label; // nom de l'agence ou mail custom, déjà résolu

  _SyndicException({
    required this.structureId,
    required this.structureName,
    required this.label,
  });
}

class _ManagementResInfoGState extends ConsumerState<ManagementResInfoG> {
  bool _isLoading = true;
  bool _itemSelected = false;
  bool delegated = false;

  List<Agency> searchResults = [];
  bool isSearching = false;

  List<_SyndicException> _syndicExceptions = [];
  bool _loadingExceptions = true;

  late final AgencySearchFlow _flow;
  late final IResidenceRepository _residenceServices;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _flow = ref.read(agencySearchFlowProvider('serviceSyndic'));
    _residenceServices = ref.read(residenceRepositoryProvider);
    _initFields();
    delegated = widget.residence.geranceRef != null ||
        (widget.residence.syndicAgency?.name.isNotEmpty ?? false);
    _loadResidenceData();
    _loadSyndicExceptions();
  }

  Future<void> _loadSyndicExceptions() async {
    final structures = await _residenceServices
        .getStructuresByResidence(widget.residence.id)
        .then((result) => result.when(
            success: (v) => v, failure: (_) => <StructureResidence>[]));

    final exceptions = <_SyndicException>[];
    for (final structure in structures) {
      if (!structure.hasDifferentSyndic || structure.id == null) continue;

      String label;
      if (structure.geranceRef != null) {
        final resolved = await _flow.resolve(structure.geranceRef!);
        label = resolved?.name ?? 'Agence introuvable';
      } else if (structure.syndicAgency != null) {
        label = structure.syndicAgency!.name;
      } else {
        continue; // hasDifferentSyndic coché mais rien de renseigné
      }

      exceptions.add(_SyndicException(
        structureId: structure.id!,
        structureName: structure.name,
        label: label,
      ));
    }

    if (mounted) {
      setState(() {
        _syndicExceptions = exceptions;
        _loadingExceptions = false;
      });
    }
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

      // Si référencé dans Gerance, on résout depuis la source à jour plutôt
      // que de se fier à une copie potentiellement figée.
      if (r.geranceRef != null) {
        r.syndicAgency = await _flow.resolve(r.geranceRef!);
      }

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

  // --- Recherche d'agence par email (via AgencySearchFlow) ---
  Future<void> _searchAgencyByEmail(String emailPart) async {
    setState(() => isSearching = true);

    final results = await _flow.search(emailPart);

    setState(() {
      if (results.isEmpty) {
        // Aucun match dans Gerance : entrée custom, non référencée.
        final newAgency = _flow.buildCustomAgency(emailPart);
        searchResults = [newAgency];
        widget.residence.syndicAgency = newAgency;
        widget.residence.geranceRef = null;
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
    final success = await _residenceServices
        .updateField(widget.residence.id, field, value)
        .then((result) => result.when(success: (v) => v, failure: (_) => false));

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
      onSubmit: (_, __, ___) => saveResidence(),
      refresh: () => setState(() {}),
    );
  }

  Widget _buildSyndicCard(String structureId, String structureName,
      String syndicLabel) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: MyTextStyle.lotName(
          structureName,
          Colors.black87,
          SizeFont.h3.size,
        ),
        subtitle: MyTextStyle.annonceDesc(
          syndicLabel,
          SizeFont.h3.size,
          1,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageStructure(
                residence: widget.residence,
                color: widget.color,
                initialExpandedStructureId: structureId,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: MyTextStyle.annonceDesc(
                    "Souhaitez-vous déléguer la gestion de votre résidence ?",
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
                          widget.residence.geranceRef = null;
                        });
                      },
                    )),
              ],
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: MyTextStyle.lotName(
                _syndicExceptions.isNotEmpty
                    ? "Vos Syndics de Copropriétés"
                    : "Votre Syndic de Copropriété",
                Colors.black87,
                SizeFont.h1.size,
              ),
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: MyTextStyle.lotName(
                "Le syndic de votre résidence",
                Colors.black87,
                SizeFont.h2.size,
                FontWeight.normal,
              ),
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
                    // Agence choisie, référencée dans Gerance
                    widget.residence.syndicAgency = agency; // cache d'affichage
                    widget.residence.geranceRef = _flow.refFor(agency);
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
                      widget.residence.geranceRef = null;
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
                if (widget.residence.geranceRef != null)
                  // Référencé dans Gerance → champs non éditables
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

            // La gérance principale n'est volontairement pas affichée en
            // carte : elle est déjà éditable ci-dessus. Seules les exceptions
            // par bâtiment (hasDifferentSyndic) sont montrées ici.
            if (!_loadingExceptions && _syndicExceptions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: MyTextStyle.lotName(
                  "Vos autres syndics",
                  Colors.black87,
                  SizeFont.h2.size,
                  FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),
              ..._syndicExceptions.map(
                (e) => _buildSyndicCard(e.structureId, e.structureName, e.label),
              ),
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
      // Non délégué : le mail saisi par l'utilisateur fait foi. Délégué :
      // mail_contact est vidé plutôt que de dupliquer le mail de l'agence -
      // la résolution se fait à la lecture (geranceRef/syndicAgency), pas
      // via une copie qui peut devenir périmée.
      'mail_contact': !delegated ? mailContact : '',
    };

    // Gestion de l'agence si délégué
    if (delegated && widget.residence.geranceRef != null) {
      // Référencé dans Gerance : on ne persiste que la référence, jamais de
      // copie (les champs affichés sont en lecture seule dans ce cas, cf.
      // build() ci-dessus).
      updatedData['geranceRef'] = widget.residence.geranceRef!.toJson();
      updatedData['syndicAgency'] = FieldValue.delete();
    } else if (delegated &&
        (widget.residence.syndicAgency?.name.isNotEmpty ?? false)) {
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
        updatedData['geranceRef'] = FieldValue.delete();
      }
    } else {
      updatedData['syndicAgency'] = FieldValue.delete();
      updatedData['geranceRef'] = FieldValue.delete();
    }

    final success = await _residenceServices
        .updateResidence(refResidence, updatedData)
        .then((result) => result.when(success: (v) => v, failure: (_) => false));

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
