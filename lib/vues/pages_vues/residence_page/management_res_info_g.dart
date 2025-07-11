import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/agency_search_result_list.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
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
  List<Agent> agents = [];
  Agent? selectedAgent;
  bool delegated = false;
  List<Agency> searchResults = [];
  bool isSearching = false;
  final DatabasesAgencyServices _agencyServices = DatabasesAgencyServices();

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initFields();
    _loadResidenceData();
    delegated = widget.residence.refGerance.isNotEmpty;
  }

  void _initFields() {
    final fields = [
      "mail_contact",
      "name",
      "numero",
      "voie",
      "street",
      "zipCode",
      "city",
      "agencyName",
      "nameAgent",
      "surnameAgent",
      "email",
      "phone",
      "lookup",
      "selectedAgent", // Ajouté pour afficher nom complet agent
    ];
    // module de recherche
    for (var field in fields) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
    }

    // Ajouter listener sur le champ 'lookup' pour la recherche
    _controllers["lookup"]!.addListener(() {
      final text = _controllers["lookup"]!.text.toLowerCase();
      searchAgencyByEmail(text);
    });
  }

  Future<void> searchAgencyByEmail(String emailPart) async {
    if (emailPart.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    final results = await _agencyServices.searchAgencyByEmail(emailPart);

    setState(() {
      searchResults = results;
      isSearching = false;
    });
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

      // Champs de la résidence
      _controllers["name"]!.text = r.name;
      _controllers["mail_contact"]!.text = r.mailContact ?? "";
      _controllers["numero"]!.text = r.numero;
      _controllers["voie"]!.text = r.voie;
      _controllers["street"]!.text = r.street;
      _controllers["zipCode"]!.text = r.zipCode;
      _controllers["city"]!.text = r.city;

      final docs =
          await _agencyServices.getDeptByRefId(r.refGerance, "serviceSyndic");

      final agencyDoc = docs.isNotEmpty ? docs.last : null;
      final agentDoc = docs.isNotEmpty ? docs.first : null;

      final agencyData = agencyDoc?.data();
      final accountantData = agentDoc?.data();

      if (agencyData != null) {
        _controllers["agencyName"]!.text = agencyData['name'] ?? '';
      }

      if (accountantData != null) {
        _controllers["email"]!.text = accountantData['mail'] ?? '';
        _controllers["phone"]!.text = accountantData['phone'] ?? '';
        final agentList = accountantData['agents'] as List<dynamic>?;

        if (agentList != null) {
          agents = agentList.map((a) {
            final map = a as Map<String, dynamic>;
            return Agent(
              nameAgent: map['name_agent'] ?? '',
              surnameAgent: map['surname_agent'] ?? '',
            );
          }).toList();

          final indexStr = r.id_gestionnaire;
          print("id_gestionnaire (raw): $indexStr");

          int? index;
          if (indexStr != null && indexStr.isNotEmpty) {
            index = int.tryParse(indexStr);
            print("id_gestionnaire (parsed index): $index");
          } else {
            print("id_gestionnaire est null ou vide");
            index = null;
          }

          if (index != null && index >= 0 && index < agents.length) {
            selectedAgent = agents[index];
            print(
                "Agent sélectionné via index: ${selectedAgent!.nameAgent} ${selectedAgent!.surnameAgent}");
          } else {
            print("Index invalide ou hors limites, fallback...");
            selectedAgent = agents.isNotEmpty
                ? agents.first
                : Agent(nameAgent: '', surnameAgent: '');
          }

          if (selectedAgent != null) {
            _controllers["nameAgent"]!.text = selectedAgent!.nameAgent;
            _controllers["surnameAgent"]!.text = selectedAgent!.surnameAgent;

            _controllers["selectedAgent"]!.text =
                "${selectedAgent!.nameAgent} ${selectedAgent!.surnameAgent}";
            print(
                "Champ gestionnaire mis à jour: ${_controllers["selectedAgent"]!.text}");
          } else {
            print("Pas d'agent sélectionné");
          }
        }
      }
    } catch (e) {
      print("Erreur: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des données")),
      );
    }

    setState(() {
      _isLoading = false;
    });
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

  Future<void> _updateField(String field, String label, String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('residences')
          .doc(widget.residence.id)
          .update({field: value});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label mis à jour')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour de $label")),
      );
    }
  }

  Widget buildField(String label, String field, {bool editable = true}) {
    return CustomTextFieldWidget(
      label: label,
      field: field,
      controller: _controllers[field]!,
      focusNode: _focusNodes[field]!,
      isEditable: editable,
      value: editable ? null : _controllers[field]!.text, // <-- ici
      onSubmit: _updateField,
      refresh: () => setState(() {}),
    );
  }

  void updateBool(bool delegatedBool) {
    setState(() {
      delegated = delegatedBool;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
            buildField("Nom de la résidence", "name"),
            buildField("Numéro", "numero", editable: false),
            buildField("Type de voie", "voie", editable: false),
            buildField("Nom de la voie", "street", editable: false),
            buildField("Code postal", "zipCode", editable: false),
            buildField("Ville", "city", editable: false),
            const SizedBox(height: 30),
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
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: width / 1.5,
                  child: MyTextStyle.annonceDesc(
                      "Souhaitez-vous déléguer la gestion de votre résidence? ",
                      SizeFont.h3.size,
                      2),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    thumbIcon: thumbIcon,
                    value: delegated,
                    onChanged: (bool value) {
                      setState(() {
                        delegated = value;
                        updateBool(delegated);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Visibility(
              visible: !delegated,
              child: Column(
                children: [
                  buildField("Mail de contact", "mail_contact"),
                  MyTextStyle.annonceDesc(
                      "Si vous ne deleguez pas la gestion de votre coproprité, merci de saisir un mail de contact pour recevoir toutes les demandes de la plateforme ",
                      SizeFont.h3.size,
                      5),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Visibility(
              visible: delegated && widget.residence.refGerance.isEmpty,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  buildField("Recherchez votre syndic", "lookup"),
                  AgencySearchResultList(
                    isSearching: isSearching,
                    searchResults: searchResults,
                    onSelect: (agency) {
                      setState(() {
                        _controllers["lookup"]!.text = agency.name;
                        _itemSelected = true;
                        searchResults = [];
                        _controllers["agencyName"]!.text = agency.name;

                        // Tu peux aussi gérer ici le chargement des agents liés
                        agents = [];
                        selectedAgent = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            Visibility(
              visible: widget.residence.refGerance.isNotEmpty && delegated,
              child: Column(
                children: [
                  buildField("Nom de l'agence", "agencyName", editable: false),
                  buildField("Gestionnaire", "selectedAgent", editable: false),
                  buildField("Email de contact", "email", editable: false),
                  buildField("Téléphone de contact", "phone", editable: false),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ButtonAdd(
                icon: (widget.residence.refGerance.isEmpty ||
                        widget.residence.refGerance == null)
                    ? Icons.add
                    : Icons.edit,
                text: (widget.residence.refGerance.isEmpty ||
                        widget.residence.refGerance == null)
                    ? "Ajouter"
                    : "Modifier",
                color: Theme.of(context).primaryColor,
                horizontal: 20,
                vertical: 10,
                size: SizeFont.h3.size,
                function: () {},
              ),
            )
          ],
        ),
      ),
    );
  }

  // Future<void> saveResidence() async {
  //   try {
  //     final docRef = FirebaseFirestore.instance
  //         .collection('residences')
  //         .doc(widget.residence.id);

  //     Map<String, dynamic> updateData = {
  //       'mailContact': _controllers["mail_contact"]!.text,
  //       'name': _controllers["name"]!.text,
  //       'numero': _controllers["numero"]!.text,
  //       'voie': _controllers["voie"]!.text,
  //       'street': _controllers["street"]!.text,
  //       'zipCode': _controllers["zipCode"]!.text,
  //       'city': _controllers["city"]!.text,
  //     };

  //     if (delegated) {
  //       if (_itemSelected) {
  //         // L’utilisateur vient de sélectionner une nouvelle agence
  //         final agencyName = _controllers["agencyName"]!.text;
  //         final Agency? agency = searchResults.firstWhere(
  //             (a) => a.name == agencyName,
  //             orElse: () => Agency(id: "", name: ""));

  //         if (agency.id.isNotEmpty) {
  //           updateData['refGerance'] = agency.id;
  //           updateData['id_gestionnaire'] =
  //               "0"; // par défaut, pas encore choisi
  //         }
  //       } else if (selectedAgent != null) {
  //         // Mise à jour de l'agent si déjà sélectionné
  //         updateData['id_gestionnaire'] =
  //             agents.indexOf(selectedAgent!).toString();
  //       }
  //     } else {
  //       // Pas de délégation, on vide refGerance et id_gestionnaire
  //       updateData['refGerance'] = "";
  //       updateData['id_gestionnaire'] = "";
  //     }

  //     await docRef.update(updateData);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Résidence mise à jour")),
  //     );
  //   } catch (e) {
  //     print("Erreur lors de la sauvegarde : $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Erreur lors de la sauvegarde")),
  //     );
  //   }
  // }
}
