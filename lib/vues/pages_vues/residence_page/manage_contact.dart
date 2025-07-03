import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_agency_services.dart'; // Gardez si nécessaire pour d'autres fonctionnalités
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/contact.dart'; // Importez votre modèle Contact
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';

class ManageContact extends StatefulWidget {
  final Color color; // La couleur peut être passée de la page parente
  final Residence residence;

  ManageContact({super.key, required this.color, required this.residence});

  @override
  State<ManageContact> createState() => ManageContactState();
}

class ManageContactState extends State<ManageContact> {
  // Liste des contacts à gérer. Initialisez-la avec des données si vous en chargez depuis une base.
  List<Contact> contacts = [];
  final DataBasesResidenceServices _residenceServices =
      DataBasesResidenceServices();

  // Map pour stocker les contrôleurs et les focus nodes dynamiques pour chaque champ de chaque contact
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
    // Vous pouvez initialiser 'contacts' ici avec des données existantes si vous en avez.
    // Par exemple: contacts = await _contactService.getContacts();
  }

  Future<void> _loadContacts() async {
    if (widget.residence.id != null) {
      // Récupère les structures en utilisant la nouvelle fonction du service
      final fetchedBuildings =
          await _residenceServices.getContactByResidence(widget.residence.id);
      // S'assure que toutes les cartes sont fermées lors du chargement
      for (var contact in fetchedBuildings) {
        contact.isExpanded = false;
      }
      setState(() {
        contacts = fetchedBuildings;
      });
    } else {
      contacts = []; // Si pas d'ID de résidence, initialise la liste comme vide
    }
  }

  // Fonction utilitaire pour initialiser et récupérer un TextEditingController et son FocusNode
  // Cela rend le code plus propre et réutilisable.
  TextEditingController _initAndGetController(String key, String? initialText) {
    _controllers.putIfAbsent(key, () => TextEditingController());
    _controllers[key]!.text = initialText ?? '';
    _focusNodes.putIfAbsent(key, () => FocusNode());
    return _controllers[key]!;
  }

  // Ajoute un nouveau contact à la liste
  void addContact() {
    setState(() {
      // Un nouveau contact est ajouté, par défaut isExpanded = true
      contacts.add(Contact(name: '', service: '', phone: ''));
    });
  }

  // Supprime un contact de la liste et dispose de ses contrôleurs
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

      _controllers['${contactPrefix}_num']?.dispose();
      _controllers.remove('${contactPrefix}_num');
      _focusNodes['${contactPrefix}_num']?.dispose();
      _focusNodes.remove('${contactPrefix}_num');

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
    await _residenceServices.removeContact(widget.residence.id!, contact);
  }

  void saveContacts() async {
    if (widget.residence.id == null) return;

    for (var contact in contacts) {
      if ((contact.name.trim().isEmpty ||
          contact.phone.trim().isEmpty ||
          contact.service.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Les champs nom, service et téléphone sont obligatoires"),
          ),
        );
        return;
      }

      if (contact.id == null) {
        // Nouveau contact : ajouter
        await _residenceServices.addContact(widget.residence.id!, contact);
      } else {
        // Contact existant : mettre à jour
        await _residenceServices.updateContact(contact.id!, contact);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contacts mis à jour avec succès")),
    );

    await _loadContacts();

    setState(() {
      for (var contact in contacts) {
        contact.isExpanded = false;
      }
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage de chaque contact sous forme de "portefeuille"
            ...contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;
              final contactPrefix =
                  'contact_$index'; // Préfixe unique pour les clés des contrôleurs

              // Initialisation des contrôleurs pour ce contact spécifique
              final nameController =
                  _initAndGetController('${contactPrefix}_name', contact.name);
              final serviceController = _initAndGetController(
                  '${contactPrefix}_service', contact.service);
              final phoneController = _initAndGetController(
                  '${contactPrefix}_phone', contact.phone);
              final mailController =
                  _initAndGetController('${contactPrefix}_mail', contact.mail);
              final numController =
                  _initAndGetController('${contactPrefix}_num', contact.num);
              final streetController = _initAndGetController(
                  '${contactPrefix}_street', contact.street);
              final cityController =
                  _initAndGetController('${contactPrefix}_city', contact.city);
              final zipcodeController = _initAndGetController(
                  '${contactPrefix}_zipcode', contact.zipcode);
              final webController =
                  _initAndGetController('${contactPrefix}_web', contact.web);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ExpansionTile(
                  key: ObjectKey(
                      contact), // Clé unique basée sur l'instance de contact
                  initiallyExpanded: contact.isExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      contact.isExpanded =
                          expanded; // Met à jour l'état du contact
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    // Contenu détaillé du contact, déplacé à l'intérieur du ExpansionTile
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextFieldWidget(
                            label: "Nom",
                            controller: nameController,
                            isEditable: true,
                            onChanged: (val) => contact.name = val,
                          ),
                          const SizedBox(height: 10),
                          CustomTextFieldWidget(
                            label: "Service",
                            controller: serviceController,
                            isEditable: true,
                            onChanged: (val) => contact.service = val,
                          ),
                          const SizedBox(height: 10),
                          CustomTextFieldWidget(
                            label: "Téléphone",
                            controller: phoneController,
                            isEditable: true,
                            keyboardType: TextInputType
                                .phone, // Type de clavier téléphone
                            onChanged: (val) => contact.phone = val,
                          ),
                          const SizedBox(height: 10),
                          CustomTextFieldWidget(
                            label: "Email",
                            controller: mailController,
                            isEditable: true,
                            keyboardType: TextInputType
                                .emailAddress, // Type de clavier email
                            onChanged: (val) => contact.mail = val,
                          ),
                          const SizedBox(height: 10),
                          // Bloc d'adresse
                          MyTextStyle.lotName(
                            "Adresse",
                            Colors.black87,
                            SizeFont.h3.size,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: CustomTextFieldWidget(
                                  label: "N°",
                                  controller: numController,
                                  isEditable: true,
                                  keyboardType: TextInputType
                                      .number, // Type de clavier numérique
                                  onChanged: (val) => contact.num = val,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: CustomTextFieldWidget(
                                  label: "Rue",
                                  controller: streetController,
                                  isEditable: true,
                                  onChanged: (val) => contact.street = val,
                                ),
                              ),
                            ],
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
                                  onChanged: (val) => contact.city = val,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: CustomTextFieldWidget(
                                  label: "Code Postal",
                                  controller: zipcodeController,
                                  isEditable: true,
                                  keyboardType: TextInputType
                                      .number, // Type de clavier numérique
                                  onChanged: (val) => contact.zipcode = val,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomTextFieldWidget(
                            label: "Site Web",
                            controller: webController,
                            isEditable: true,
                            keyboardType:
                                TextInputType.url, // Type de clavier URL
                            onChanged: (val) => contact.web = val,
                          ),
                          const SizedBox(height: 20),
                          _removeContactButton(
                              index,
                              contact
                                  .id!), // Bouton supprimer pour chaque contact
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
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
          ],
        ),
      ),
    );
  }

  // Widget utilitaire pour le bouton de suppression
  Widget _removeContactButton(int index, String contactId) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => removeContact(index, contactId),
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
