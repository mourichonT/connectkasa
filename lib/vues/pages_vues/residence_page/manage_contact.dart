import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/contact_repository_provider.dart';
import 'package:konodal/core/repositories/contact_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/contact.dart'; // Importez votre modèle Contact
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/components/address_search_field.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageContact extends ConsumerStatefulWidget {
  final Color color; // La couleur peut être passée de la page parente
  final Residence residence;

  const ManageContact({super.key, required this.color, required this.residence});

  @override
  ConsumerState<ManageContact> createState() => ManageContactState();
}

class ManageContactState extends ConsumerState<ManageContact> {
  // Liste des contacts à gérer. Initialisez-la avec des données si vous en chargez depuis une base.
  List<Contact> contacts = [];
  late final IContactRepository _contactRepository;

  // État d'ouverture des cartes : purement local (UI), jamais persisté en
  // base. Basé sur l'identité de l'objet (comme ObjectKey ci-dessous), donc
  // il suit le bon contact même si la liste est réordonnée.
  final Set<Contact> _expandedContacts = {};

  // Map pour stocker les contrôleurs et les focus nodes dynamiques pour chaque champ de chaque contact
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _contactRepository = ref.read(contactRepositoryProvider);
    _loadContacts();
    // Vous pouvez initialiser 'contacts' ici avec des données existantes si vous en avez.
    // Par exemple: contacts = await _contactService.getContacts();
  }

  Future<void> _loadContacts() async {
    // Récupère les structures en utilisant la nouvelle fonction du service
    final fetchedBuildings = await _contactRepository
        .getContactsByResidence(widget.residence.id)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => <Contact>[]));
    setState(() {
      contacts = fetchedBuildings;
      // Toutes les cartes sont fermées au chargement.
      _expandedContacts.clear();
    });
    }

  // Fonction utilitaire pour initialiser et récupérer un TextEditingController et son FocusNode
  // Cela rend le code plus propre et réutilisable.
  TextEditingController _initAndGetController(String key, String? initialText) {
    _controllers.putIfAbsent(key, () => TextEditingController());
    _controllers[key]!.text = initialText ?? '';
    _focusNodes.putIfAbsent(key, () => FocusNode());
    return _controllers[key]!;
  }

  // Ajoute un nouveau contact à la liste (fermé par défaut)
  void addContact() {
    setState(() {
      contacts.add(Contact(
          name: '',
          service: '',
          phone: '',
          web: '',
          mail: '',
          address: Address()));
    });
  }

  // Détache un contact de CETTE résidence (jamais un delete : un contact
  // partagé avec d'autres résidences doit y rester visible - cf.
  // IContactRepository.unlinkResidence).
  void removeContact(int index, String contact) async {
    setState(() {
      final contactPrefix = 'contact_$index';
      // Dispose et supprime des maps
      _controllers['${contactPrefix}_name']?.dispose();
      _controllers.remove('${contactPrefix}_name');
      _focusNodes['${contactPrefix}_name']?.dispose();
      _focusNodes.remove('${contactPrefix}_name');

      _controllers['${contactPrefix}_service']?.dispose();
      _controllers.remove('${contactPrefix}_service');
      _focusNodes['${contactPrefix}_service']?.dispose();
      _focusNodes.remove('${contactPrefix}_service');

      _controllers['${contactPrefix}_phone']?.dispose();
      _controllers.remove('${contactPrefix}_phone');
      _focusNodes['${contactPrefix}_phone']?.dispose();
      _focusNodes.remove('${contactPrefix}_phone');

      _controllers['${contactPrefix}_mail']?.dispose();
      _controllers.remove('${contactPrefix}_mail');
      _focusNodes['${contactPrefix}_mail']?.dispose();
      _focusNodes.remove('${contactPrefix}_mail');

      _controllers['${contactPrefix}_street']?.dispose();
      _controllers.remove('${contactPrefix}_street');
      _focusNodes['${contactPrefix}_street']?.dispose();
      _focusNodes.remove('${contactPrefix}_street');

      _controllers['${contactPrefix}_city']?.dispose();
      _controllers.remove('${contactPrefix}_city');
      _focusNodes['${contactPrefix}_city']?.dispose();
      _focusNodes.remove('${contactPrefix}_city');

      _controllers['${contactPrefix}_zipcode']?.dispose();
      _controllers.remove('${contactPrefix}_zipcode');
      _focusNodes['${contactPrefix}_zipcode']?.dispose();
      _focusNodes.remove('${contactPrefix}_zipcode');

      _controllers['${contactPrefix}_web']?.dispose();
      _controllers.remove('${contactPrefix}_web');
      _focusNodes['${contactPrefix}_web']?.dispose();
      _focusNodes.remove('${contactPrefix}_web');
      contacts.removeAt(index);
    });
    await _contactRepository.unlinkResidence(contact, widget.residence.id);
  }

  /// Champs comparés entre la saisie et un candidat de rapprochement (hors
  /// nom, déjà garanti identique par nameNormalized) - un champ ne compte
  /// que s'il est NON VIDE des deux côtés. Sert de preuve à l'appui dans la
  /// modale de confirmation ("les deux ont : ...").
  List<String> _matchingFieldLabels(Contact input, Contact candidate) {
    String norm(String? s) => (s ?? '').trim().toLowerCase();
    final labels = <String>[];
    if (norm(input.phone).isNotEmpty && norm(input.phone) == norm(candidate.phone)) {
      labels.add('téléphone');
    }
    if (norm(input.mail).isNotEmpty && norm(input.mail) == norm(candidate.mail)) {
      labels.add('email');
    }
    if (norm(input.service).isNotEmpty && norm(input.service) == norm(candidate.service)) {
      labels.add('service');
    }
    if (norm(input.address.city).isNotEmpty &&
        norm(input.address.city) == norm(candidate.address.city)) {
      labels.add('ville');
    }
    if (norm(input.address.zipCode).isNotEmpty &&
        norm(input.address.zipCode) == norm(candidate.address.zipCode)) {
      labels.add('code postal');
    }
    if (norm(input.web).isNotEmpty && norm(input.web) == norm(candidate.web)) {
      labels.add('site web');
    }
    return labels;
  }

  /// Plusieurs homonymes possibles (rare) : un seul dialog, pour le candidat
  /// ayant le plus de champs en commun avec la saisie - simplicité UX plutôt
  /// qu'exhaustivité pour ce cas marginal.
  Contact _pickBestMatch(Contact input, List<Contact> candidates) {
    candidates.sort((a, b) => _matchingFieldLabels(input, b)
        .length
        .compareTo(_matchingFieldLabels(input, a).length));
    return candidates.first;
  }

  Future<bool> _showDuplicateConfirmDialog(
      Contact candidate, List<String> matchingLabels) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: MyTextStyle.lotDesc(
          "Un contact similaire à ${candidate.name} a été trouvé en base. "
          "Les deux ont : ${matchingLabels.isEmpty ? 'le même nom' : matchingLabels.join(', ')}. "
          "Est-ce le même contact ?",
          SizeFont.h2.size,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Oui"),
          ),
        ],
      ),
    );
    // Un dismiss (tap en dehors) équivaut à "Non" - jamais de rattachement
    // accidentel à un contact qui n'est peut-être pas le bon.
    return result ?? false;
  }

  void saveContacts() async {
    // Un contact déjà persisté (id != null) est verrouillé : un CS member ne
    // peut plus modifier ses champs une fois créé (ça changerait la fiche
    // pour toutes les résidences qui la partagent) - seule la création de
    // nouveaux contacts passe par cette sauvegarde. Cf. firestore.rules et
    // Contact.isApproved.
    final newContacts = contacts.where((contact) => contact.id == null).toList();

    for (var contact in newContacts) {
      if ((contact.name.trim().isEmpty ||
          contact.phone.trim().isEmpty ||
          contact.service.trim().isEmpty)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Les champs nom, service et téléphone sont obligatoires"),
          ),
        );
        return;
      }

      contact.name = capitalizeFirstLetter(contact.name);
      if (contact.address.street.isNotEmpty) {
        contact.address.street = capitalizeFirstLetter(contact.address.street);
      }
      if (contact.address.city.isNotEmpty) {
        contact.address.city = capitalizeFirstLetter(contact.address.city);
      }
      if ((contact.address.complement ?? '').isNotEmpty) {
        contact.address.complement =
            capitalizeFirstLetter(contact.address.complement!);
      }
      // mail et phone : jamais capitalizeFirstLetter (décision produit).

      // Recherche d'un contact déjà existant portant le même nom (comparaison
      // insensible à la casse via nameNormalized) avant de créer un doublon.
      final nameNormalized = contact.name.trim().toLowerCase();
      final candidates = await _contactRepository
          .findContactsByNameNormalized(nameNormalized)
          .then((result) => result.when(success: (v) => v, failure: (_) => <Contact>[]));

      if (candidates.isNotEmpty) {
        final best = _pickBestMatch(contact, candidates);
        final matchingLabels = _matchingFieldLabels(contact, best);
        if (!mounted) return;
        final sameContact = await _showDuplicateConfirmDialog(best, matchingLabels);
        if (sameContact) {
          final linkResult =
              await _contactRepository.linkResidence(best.id!, widget.residence.id);
          if (linkResult.isFailure) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Erreur lors du rattachement de ${best.name} : ${linkResult.errorOrNull}"),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          continue; // Rattaché à l'existant : pas de nouvelle fiche créée.
        }
        // "Non" : l'utilisateur confirme qu'il s'agit d'un contact distinct
        // malgré le nom identique -> tombe dans la création ci-dessous.
      }

      final createResult =
          await _contactRepository.createContact(widget.residence.id, contact);
      if (createResult.isFailure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Erreur lors de l'enregistrement de ${contact.name} : ${createResult.errorOrNull}"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contacts mis à jour avec succès")),
    );

    // _loadContacts() vide déjà _expandedContacts (toutes les cartes
    // fermées après rechargement).
    await _loadContacts();
  }

  @override
  void dispose() {
    // Dispose de tous les contrôleurs et focus nodes restants dans la map
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
          "Gestion des Contacts",
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
            // Affichage de chaque contact sous forme de "portefeuille"
            ...contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;
              // Un contact déjà persisté est partagé entre résidences et
              // verrouillé : lecture seule ici, seul un Super Admin (BO) peut
              // corriger ses champs après validation (contact.isApproved).
              final isLocked = contact.id != null;
              final contactPrefix =
                  'contact_$index'; // Préfixe unique pour les clés des contrôleurs

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ExpansionTile(
                  key: ObjectKey(
                      contact), // Clé unique basée sur l'instance de contact
                  initiallyExpanded: _expandedContacts.contains(contact),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      if (expanded) {
                        _expandedContacts.add(contact);
                      } else {
                        _expandedContacts.remove(contact);
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
                              // Affiche le nom du contact, ou un placeholder si vide
                              contact.name.isNotEmpty
                                  ? contact.name
                                  : "Nouveau Contact",
                              Colors.black87,
                              SizeFont.h3.size,
                            ),
                            if (contact.service
                                .isNotEmpty) // Affiche le service si défini
                              MyTextStyle.lotDesc(
                                "Service: ${contact.service}",
                                SizeFont.h3.size,
                              ),
                            if (isLocked && !contact.isApproved)
                              MyTextStyle.lotDesc(
                                "En attente de validation",
                                SizeFont.h3.size,
                                null,
                                null,
                                Colors.orange,
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
                        children: isLocked
                            ? _lockedFields(contact)
                            : _editableFields(contactPrefix, contact, width),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 8),
                        child: _removeContactButton(index, contact.id),
                      ),
                    ),
                  ],
                ),
              );
            }),
                  Center(
                    child: ButtonAdd(
                      color: Colors.transparent,
                      icon: Icons.add,
                      text: "Ajouter un contact",
                      size: SizeFont.h3.size,
                      horizontal: 20,
                      vertical: 10,
                      colorText: widget.color,
                      borderColor: Colors.transparent,
                      function: addContact,
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
                  text: "Enregistrer les contacts",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: Colors.white,
                  borderColor: Colors.transparent,
                  function: saveContacts, // Associez le bouton "Enregistrer"
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Contact pas encore créé (id == null) : formulaire éditable, identique au
  /// comportement historique de cet écran.
  List<Widget> _editableFields(String contactPrefix, Contact contact, double width) {
    final nameController =
        _initAndGetController('${contactPrefix}_name', contact.name);
    final phoneController =
        _initAndGetController('${contactPrefix}_phone', contact.phone);
    final mailController =
        _initAndGetController('${contactPrefix}_mail', contact.mail);
    final streetController =
        _initAndGetController('${contactPrefix}_street', contact.address.street);
    final cityController =
        _initAndGetController('${contactPrefix}_city', contact.address.city);
    final zipcodeController =
        _initAndGetController('${contactPrefix}_zipcode', contact.address.zipCode);
    final webController =
        _initAndGetController('${contactPrefix}_web', contact.web);

    return [
      CustomTextFieldWidget(
        label: "Nom",
        controller: nameController,
        isEditable: true,
        onChanged: (val) => contact.name = val,
      ),
      const SizedBox(height: 10),
      MyDropDownMenu(
        height: 90,
        width,
        "Service",
        contact.service,
        false,
        items: TypeList.servicePrestaList,
        onValueChanged: (value) {
          setState(() {
            contact.service = value;
          });
        },
      ),
      const SizedBox(height: 10),
      CustomTextFieldWidget(
        label: "Téléphone",
        controller: phoneController,
        isEditable: true,
        keyboardType: TextInputType.phone,
        onChanged: (val) => contact.phone = val,
      ),
      const SizedBox(height: 10),
      CustomTextFieldWidget(
        label: "Email",
        controller: mailController,
        isEditable: true,
        keyboardType: TextInputType.emailAddress,
        onChanged: (val) => contact.mail = val,
      ),
      const SizedBox(height: 10),
      MyTextStyle.lotName("Adresse", Colors.black87, SizeFont.h3.size),
      const SizedBox(height: 10),
      AddressSearchField(
        label: "Adresse",
        controller: streetController,
        onManualEdit: () {
          contact.address.codeQualite = '60';
          contact.address.street = streetController.text;
        },
        onSelected: (suggestion) {
          setState(() {
            contact.address.codeQualite = '00';
            contact.address.street = streetController.text;
            cityController.text = suggestion.city;
            zipcodeController.text = suggestion.postcode;
            contact.address.city = suggestion.city;
            contact.address.zipCode = suggestion.postcode;
          });
        },
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomTextFieldWidget(
              label: "Ville",
              controller: cityController,
              isEditable: true,
              onChanged: (val) => contact.address.city = val,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: CustomTextFieldWidget(
              label: "Code Postal",
              controller: zipcodeController,
              isEditable: true,
              keyboardType: TextInputType.number,
              onChanged: (val) => contact.address.zipCode = val,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      CustomTextFieldWidget(
        label: "Site Web",
        controller: webController,
        isEditable: true,
        keyboardType: TextInputType.url,
        onChanged: (val) => contact.web = val,
      ),
    ];
  }

  /// Contact déjà persisté : lecture seule (potentiellement partagé avec
  /// d'autres résidences - cf. commentaire saveContacts).
  List<Widget> _lockedFields(Contact contact) {
    return [
      CustomTextFieldWidget(label: "Nom", value: contact.name),
      const SizedBox(height: 10),
      CustomTextFieldWidget(label: "Service", value: contact.service),
      const SizedBox(height: 10),
      CustomTextFieldWidget(label: "Téléphone", value: contact.phone),
      const SizedBox(height: 10),
      CustomTextFieldWidget(label: "Email", value: contact.mail),
      const SizedBox(height: 10),
      MyTextStyle.lotName("Adresse", Colors.black87, SizeFont.h3.size),
      const SizedBox(height: 10),
      CustomTextFieldWidget(label: "Adresse", value: contact.address.street),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomTextFieldWidget(
                label: "Ville", value: contact.address.city),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: CustomTextFieldWidget(
                label: "Code Postal", value: contact.address.zipCode),
          ),
        ],
      ),
      const SizedBox(height: 10),
      CustomTextFieldWidget(label: "Site Web", value: contact.web),
    ];
  }

  // Widget utilitaire pour le bouton de suppression/détachement
  Widget _removeContactButton(int index, String? contactId) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          if (contactId != null) {
            removeContact(index, contactId);
          } else {
            setState(() {
              contacts.removeAt(index);
            });
          }
        },
        icon: const Icon(Icons.delete_forever, color: Colors.black54),
        label: MyTextStyle.postDesc(
          "Supprimer le contact",
          SizeFont.h3.size,
          Colors.black54,
        ),
      ),
    );
  }
}
