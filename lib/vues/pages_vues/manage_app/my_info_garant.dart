import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/dependent_entry.dart';
import 'package:konodal/controllers/features/job_entry.dart';
import 'package:konodal/controllers/features/justif_document.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/core/providers/docs_repository_provider.dart';
import 'package:konodal/core/providers/garant_providers.dart';
import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/docs_repository.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/controllers/features/income_entry.dart';
import 'package:konodal/models/enum/icons_extension.dart';
import 'package:konodal/models/enum/nationality_list.dart';
import 'package:konodal/models/enum/tenant_list.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/document_model.dart';
import 'package:konodal/models/pages_models/guarantor_info.dart';
import 'package:konodal/vues/widget_view/components/address_search_field.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/import_docs.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class MyGarantInfos extends ConsumerStatefulWidget {
  final String uid; // UID de l'utilisateur (locataire)
  final GuarantorInfo? garant; // ID du garant
  final Color color;

  const MyGarantInfos({
    super.key,
    required this.uid,
    this.garant,
    required this.color,
  });

  @override
  ConsumerState<MyGarantInfos> createState() => _MyGarantInfosState();
}

class _MyGarantInfosState extends ConsumerState<MyGarantInfos> {
  late final IUserRepository _userServices;
  late final IStorageRepository _storageServices;
  late final IDocsRepository docsRepository;

  //Controllers
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController birthday = TextEditingController();
  TextEditingController birthdayController = TextEditingController();
  TextEditingController placeOfBorn = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phone = TextEditingController();

  // Adresse actuelle du garant (dossier de location) : contrôleurs
  // persistants, comme pour l'adresse du locataire dans my_infos_rent.dart.
  final TextEditingController _addressStreetController =
      TextEditingController();
  // "00" (RNVP) si _addressStreetController a été rempli en sélectionnant
  // une suggestion de l'API Adresse, "60" si saisie/modifiée manuellement.
  String _addressCodeQualite = '60';
  final TextEditingController _addressComplementController =
      TextEditingController();
  final TextEditingController _addressZipCodeController =
      TextEditingController();
  final TextEditingController _addressCityController =
      TextEditingController();

  Timestamp? birthdayValue;
  String sex = "";
  String _nationality = "";
  String _familySituation = "";
  String _relationToTenant = "";
  List<DependentEntry> _dependents = [];
  String fileExtension = "";
  String docUrl = "";

  GuarantorInfo? currentGarant;
  GuarantorInfo? garantUser;
  bool isLoading = true;
  // Liste des documents & justificatifs
  List<JustifDocument> documents = [];
  List<IncomeEntry> incomeEntries = [];
  List<JobEntry> jobEntries = [];
  // État d'ouverture des cartes d'activité : purement local (UI), jamais
  // persisté en base. Basé sur l'identité de l'objet (comme
  // ManageStructure/_expandedBuildings) - fonctionne car les champs de
  // JobEntry sont maintenant mutables (plus de remplacement de l'objet à
  // chaque modification).
  final Set<JobEntry> _expandedJobs = {};

  @override
  void initState() {
    super.initState();
    _userServices = ref.read(userRepositoryProvider);
    _storageServices = ref.read(storageRepositoryProvider);
    docsRepository = ref.read(docsRepositoryProvider);
    currentGarant = widget.garant;
    fetchGarantUser();
  }

  @override
  void dispose() {
    // Dispose des controllers
    name.dispose();
    surname.dispose();
    birthday.dispose();
    birthdayController.dispose();
    placeOfBorn.dispose();
    mail.dispose();
    phone.dispose();
    _addressStreetController.dispose();
    _addressComplementController.dispose();
    _addressZipCodeController.dispose();
    _addressCityController.dispose();

    super.dispose();
  }

  Future<void> fetchGarantUser() async {
    GuarantorInfo? user;

    if (widget.garant != null &&
        widget.garant!.id != null &&
        widget.garant!.id!.isNotEmpty) {
      // Garant existant
      user = widget.garant;
      name.text = user!.name;
      surname.text = user.surname;
      birthday.text = DateFormat('dd/MM/yyyy').format(user.birthday.toDate());
      birthdayValue = user.birthday;
      birthdayController.text =
          DateFormat('dd/MM/yyyy').format(user.birthday.toDate());
      placeOfBorn.text = user.placeOfborn;
      _nationality = user.nationality;
      sex = user.sex;
      mail.text = user.email;
      phone.text = user.phone;
      _relationToTenant = user.relationToTenant;
      _familySituation = user.familySituation;
      _dependents = List<DependentEntry>.from(user.dependents);
      _addressStreetController.text = user.address.street;
      _addressCodeQualite = user.address.codeQualite;
      _addressComplementController.text = user.address.complement ?? '';
      _addressZipCodeController.text = user.address.zipCode;
      _addressCityController.text = user.address.city;

      appLog("Incomes length: ${incomeEntries.length}");
      appLog("Job incomes length: ${jobEntries.length}");
    } else {
      // Nouveau garant → on initialise un UserInfo vide
      user = GuarantorInfo(
        name: '',
        surname: '',
        email: '',
        birthday: Timestamp.now(),
        nationality: '',
        phone: '',
        sex: '',
        placeOfborn: '',
        incomes: [],
        jobIncomes: [],
        familySituation: '',
        dependents: [],
      );
    }

    if (mounted) {
      setState(() {
        garantUser = user;
        isLoading = false;
        jobEntries = List<JobEntry>.from(user?.jobIncomes ?? []);
        incomeEntries = List<IncomeEntry>.from(user?.incomes ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: AppLoader()),
      );
    }

    if (garantUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Aucun garant trouvé.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          widget.garant != null && widget.garant!.name.isNotEmpty
              ? "${widget.garant!.name} ${widget.garant!.surname}"
              : "Mon dossier garant",
          Colors.black87,
          SizeFont.h1.size,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.lotName(
                "Information personnel", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 20),
            CustomTextFieldWidget(
              label: "Nom",
              text: name.text,
              controller: name,
              isEditable: true,
            ),
            CustomTextFieldWidget(
              label: "Prénom(s)",
              text: surname.text,
              controller: surname,
              isEditable: true,
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextFieldWidget(
                    label: "Date de naissance",
                    controller:
                        birthdayController, // <-- NE PAS recréer un controller
                    isEditable: true,
                    pickDate: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: birthdayValue?.toDate() ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          birthdayValue = Timestamp.fromDate(pickedDate);
                          birthdayController.text =
                              DateFormat('dd/MM/yyyy').format(pickedDate);
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: MyDropDownMenu(
                      width,
                      height: 90,
                      "Sexe",
                      sex,
                      false,
                      items: TypeList.sex,
                      onValueChanged: (value) {
                        setState(() {
                          sex = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CustomTextFieldWidget(
                      label: "Lieu",
                      text: placeOfBorn.text,
                      controller: placeOfBorn,
                      isEditable: true,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: MyDropDownMenu(
                    width,
                    "Nationalité",
                    _nationality.isEmpty ? "Nationalité" : _nationality,
                    false,
                    items: NationalityList.all(),
                    onValueChanged: (value) {
                      setState(() => _nationality = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            MyTextStyle.lotName(
                "Contact du garant", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 20),
            CustomTextFieldWidget(
              keyboardType: TextInputType.emailAddress,
              label: "Email",
              text: mail.text,
              controller: mail,
              isEditable: true,
            ),
            SizedBox(height: 20),
            CustomTextFieldWidget(
              keyboardType: TextInputType.phone,
              label: "Téléphone principal",
              text: phone.text,
              controller: phone,
              isEditable: true,
            ),
            SizedBox(height: 20),
            AddressSearchField(
              controller: _addressStreetController,
              onManualEdit: () => _addressCodeQualite = '60',
              onSelected: (suggestion) {
                setState(() {
                  _addressCodeQualite = '00';
                  _addressZipCodeController.text = suggestion.postcode;
                  _addressCityController.text = suggestion.city;
                });
              },
            ),
            CustomTextFieldWidget(
              label: "Complément d'adresse",
              controller: _addressComplementController,
              isEditable: true,
              onChanged: (_) {},
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextFieldWidget(
                    keyboardType: TextInputType.number,
                    label: "Code postal",
                    controller: _addressZipCodeController,
                    isEditable: true,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextFieldWidget(
                    label: "Ville",
                    controller: _addressCityController,
                    isEditable: true,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            MyTextStyle.lotName(
                "Situation du garant", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 20),
            MyDropDownMenu(
              width,
              "Lien avec le locataire",
              _relationToTenant.isEmpty
                  ? "Lien avec le locataire"
                  : _relationToTenant,
              false,
              items: TenantList.liensGarantLocataire(),
              onValueChanged: (value) {
                setState(() => _relationToTenant = value);
              },
            ),
            SizedBox(height: 20),
            MyDropDownMenu(
              width,
              "Situation familiale",
              _familySituation.isEmpty
                  ? "Situation familiale"
                  : _familySituation,
              false,
              items: TenantList.situationsFamiliales(),
              onValueChanged: (value) {
                setState(() => _familySituation = value);
              },
            ),
            SizedBox(height: 30),
            MyTextStyle.lotName(
                "Personnes à charge", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 30),
            ..._buildDependentsSection(width),
            Center(
              child: ButtonAdd(
                color: Colors.transparent,
                icon: Icons.add,
                text: "Ajouter une personne à charge",
                size: SizeFont.h3.size,
                horizontal: 20,
                vertical: 10,
                colorText: widget.color,
                borderColor: Colors.transparent,
                function: _addDependent,
              ),
            ),
            const SizedBox(height: 30),
            MyTextStyle.lotName(
                "Emploi du garant", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 20),
            ..._buildJobSection(width),
            const SizedBox(height: 30),
            Center(
              child: ButtonAdd(
                color: Colors.transparent,
                icon: Icons.add,
                text: "Ajouter une activité",
                size: SizeFont.h3.size,
                horizontal: 20,
                vertical: 10,
                colorText: widget.color,
                borderColor: Colors.transparent,
                function: addJobEntry,
              ),
            ),
            const SizedBox(height: 30),
            MyTextStyle.lotName(
                "Revenus du garant", Colors.black, SizeFont.h2.size),
            const SizedBox(height: 20),
            ..._buildIncomeSection(width),
            Center(
              child: ButtonAdd(
                color: Colors.transparent,
                icon: Icons.add,
                text: "Ajouter un revenu",
                size: SizeFont.h3.size,
                horizontal: 20,
                vertical: 10,
                colorText: widget.color,
                borderColor: Colors.transparent,
                function: addIncomeEntry,
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 30),
            MyTextStyle.lotName(
              "Documents & justificatifs",
              Colors.black,
              SizeFont.h2.size,
            ),
            const SizedBox(height: 30),
            if (currentGarant?.id == null)
              const Center(child: Text('Aucun document trouvé.'))
            else
              Builder(builder: (context) {
                final documentsAsync = ref.watch(garantDocumentsProvider(
                    (tenantUid: widget.uid, garantId: currentGarant!.id!)));
                return documentsAsync.when(
                  loading: () =>
                      const Center(child: AppLoader()),
                  error: (error, stackTrace) =>
                      Center(child: Text('Erreur : $error')),
                  data: (documentList) {
                    if (documentList.isEmpty) {
                      return const Center(
                          child: Text('Aucun document trouvé.'));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: documentList.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final docMap = documentList[index];
                        final String docId = docMap['id'];
                        final DocumentModel doc = docMap['document'];

                        IconsExtension? fileType = getFileType(doc.extension);

                        return ListTile(
                          leading: fileType != null
                              ? fileType.icon
                              : Image.asset(
                                  'images/icon_extension/default.png'),
                          title: Text(doc.type),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download_rounded),
                                onPressed: () async {
                                  final url = Uri.parse(doc.documentPathRecto);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Impossible de télécharger le document"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeDoc(
                                      doc.documentPathRecto,
                                      widget.uid,
                                      docId)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            Column(
              children: [
                ...documents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 30, bottom: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyDropDownMenu(
                          width,
                          "Type de document",
                          doc.docType.isEmpty
                              ? "Type de document"
                              : doc.docType,
                          false,
                          items: TenantList.docsTypeList(),
                          onValueChanged: (value) {
                            setState(() {
                              documents[index].docType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ImportDocs(
                          racineFolder: "user",
                          filename: [widget.uid],
                          folderName: "doc&justif",
                          title: "",
                          onDocumentUploaded: (downloadUrl, extension) {
                            setState(() {
                              // docUrl = downloadUrl;
                              documents[index].fileUrl = downloadUrl;
                              // On utilise index ici
                              fileExtension = extension;
                            });
                            ref.invalidate(garantDocumentsProvider(
                                (tenantUid: widget.uid,
                                  garantId: widget.garant!.id!)));
                            downloadImagePath(downloadUrl,
                                extension); // Appel de ta fonction existante
                          },
                        )
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Center(
                  child: ButtonAdd(
                    color: Colors.transparent,
                    icon: Icons.add,
                    text: "Ajouter un document",
                    size: SizeFont.h3.size,
                    horizontal: 20,
                    vertical: 10,
                    colorText: widget.color,
                    borderColor: Colors.transparent,
                    function: () {
                      setState(() {
                        documents.add(JustifDocument(docType: ""));
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ButtonAdd(
                  color: widget.color,
                  text: "Enregistrer",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: Colors.white,
                  borderColor: widget.color,
                  function: saveGarantInfo,
                ),
                if (currentGarant != null)
                  ButtonAdd(
                      color: Colors.transparent,
                      text: "Supprimer",
                      size: SizeFont.h3.size,
                      horizontal: 20,
                      vertical: 10,
                      colorText: Colors.red[800]!,
                      borderColor: Colors.red[800]!,
                      function: () {
                        _userServices.deleteGarant(
                            widget.uid, currentGarant!.id!);
                        Navigator.pop(context);
                      }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void addIncomeEntry() {
    setState(() {
      incomeEntries.add(IncomeEntry(label: '', amount: ''));
    });
  }

  // Fonctions utilitaires (identiques à MyInfosRent)
  List<Widget> _buildJobSection(double width) {
    return jobEntries.asMap().entries.map((entry) {
      int index = entry.key;
      JobEntry job = entry.value;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ExpansionTile(
          key: ObjectKey(job),
          initiallyExpanded: _expandedJobs.contains(job),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedJobs.add(job);
              } else {
                _expandedJobs.remove(job);
              }
            });
          },
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: MyTextStyle.lotName(
            job.profession.isNotEmpty
                ? (job.typeContract.isNotEmpty
                    ? "${job.profession} - ${job.typeContract}"
                    : job.profession)
                : "Nouvelle activité",
            Colors.black87,
            SizeFont.h2.size,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyDropDownMenu(
                    width,
                    "Activité professionnelle",
                    job.profession,
                    false,
                    items: TenantList.secteursActivite(),
                    onValueChanged: (value) {
                      setState(() => job.profession = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  MyDropDownMenu(
                    width,
                    "Type de contrat",
                    job.typeContract,
                    false,
                    items: TenantList.jobcontractList(),
                    onValueChanged: (value) {
                      setState(() => job.typeContract = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomTextFieldWidget(
                    label: "Date d'entrée",
                    controller: TextEditingController(
                      text: job.entryJobDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(job.entryJobDate!.toDate())
                          : '',
                    ),
                    isEditable: true,
                    pickDate: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(
                            () => job.entryJobDate = Timestamp.fromDate(pickedDate));
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _removeJob("l'activité", index),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildIncomeSection(double width) {
    return incomeEntries.asMap().entries.map((entry) {
      int index = entry.key;
      IncomeEntry income = entry.value;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MyDropDownMenu(
                  width,
                  height: 90,
                  "Type de revenu",
                  income.label.isEmpty ? "Type de revenu" : income.label,
                  false,
                  items: TenantList.incomesType(),
                  onValueChanged: (value) {
                    setState(() {
                      incomeEntries[index] = IncomeEntry(
                          label: value, amount: incomeEntries[index].amount);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomTextFieldWidget(
                  keyboardType: TextInputType.number,
                  label: "Montant",
                  suffixText: "€",
                  controller: TextEditingController(text: income.amount),
                  isEditable: true,
                  onChanged: (val) {
                    incomeEntries[index] = IncomeEntry(
                        label: incomeEntries[index].label, amount: val);
                  },
                ),
              ),
            ],
          ),
          _remove("le revenu", index),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  Widget _removeJob(String object, int index) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            jobEntries.removeAt(index);
          });
        },
        icon: const Icon(Icons.delete_forever, color: Colors.black54),
        label: MyTextStyle.postDesc(
          "Supprimer $object",
          SizeFont.h3.size,
          Colors.black54,
        ),
      ),
    );
  }

  Widget _remove(String label, int index) => TextButton(
        onPressed: () {
          setState(() => incomeEntries.removeAt(index));
        },
        child: Text("Supprimer $label"),
      );

  void addJobEntry() {
    setState(() {
      final job =
          JobEntry(profession: "", typeContract: "", entryJobDate: null);
      jobEntries.add(job);
      _expandedJobs.add(job);
    });
  }

  void _addDependent() {
    setState(() => _dependents.add(DependentEntry(type: '', count: '')));
  }

  void _removeDependent(int index) {
    setState(() => _dependents.removeAt(index));
  }

  List<Widget> _buildDependentsSection(double width) {
    return _dependents.asMap().entries.map((entry) {
      final index = entry.key;
      final dependent = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: MyDropDownMenu(
                    width,
                    "Catégorie",
                    dependent.type.isEmpty ? "Catégorie" : dependent.type,
                    false,
                    items: TenantList.typesPersonneCharge(),
                    onValueChanged: (value) {
                      setState(() => _dependents[index] =
                          DependentEntry(type: value, count: dependent.count));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: CustomTextFieldWidget(
                    text: "Nombre",
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: dependent.count),
                    isEditable: true,
                    onChanged: (val) {
                      _dependents[index] =
                          DependentEntry(type: dependent.type, count: val);
                    },
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _removeDependent(index),
              child: const Text("Supprimer cette catégorie"),
            ),
          ],
        ),
      );
    }).toList();
  }

  void saveGarantInfo() async {
    FocusScope.of(context).unfocus();

    if (name.text.isEmpty ||
        surname.text.isEmpty ||
        mail.text.isEmpty ||
        birthdayValue == null ||
        sex.isEmpty ||
        _nationality.isEmpty ||
        placeOfBorn.text.isEmpty ||
        phone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? newGarantId;

    final formattedName = capitalizeFirstLetter(name.text);
    final formattedSurname = capitalizeFirstLetter(surname.text);
    final formattedPlaceOfBorn = capitalizeFirstLetter(placeOfBorn.text);
    for (final job in jobEntries) {
      job.profession = capitalizeFirstLetter(job.profession);
    }

    if (currentGarant != null) {
      // Mise à jour existante
      GuarantorInfo updatedGarant = GuarantorInfo(
        id: currentGarant!.id,
        email: mail.text,
        name: formattedName,
        surname: formattedSurname,
        birthday: birthdayValue!,
        sex: sex,
        nationality: _nationality,
        placeOfborn: formattedPlaceOfBorn,
        incomes: incomeEntries,
        jobIncomes: jobEntries,
        dependents: _dependents,
        familySituation: _familySituation,
        relationToTenant: _relationToTenant,
        phone: phone.text,
        address: Address(
          street: _addressStreetController.text,
          complement: _addressComplementController.text.isEmpty
              ? null
              : _addressComplementController.text,
          zipCode: _addressZipCodeController.text,
          city: _addressCityController.text,
          codeQualite: _addressCodeQualite,
        ),
      );

      newGarantId = await _userServices
          .updateSingleGarant(
            garant: updatedGarant,
            uid: widget.uid,
            garantDocId: currentGarant!.id!,
          )
          .then((result) => result.when(success: (v) => v, failure: (_) => null));
    } else {
      // Création d’un nouveau garant (sans ID au début)
      GuarantorInfo tempGarant = GuarantorInfo(
        id: null,
        email: mail.text,
        name: formattedName,
        surname: formattedSurname,
        birthday: birthdayValue!,
        sex: sex,
        nationality: _nationality,
        placeOfborn: formattedPlaceOfBorn,
        incomes: incomeEntries,
        jobIncomes: jobEntries,
        dependents: _dependents,
        familySituation: _familySituation,
        relationToTenant: _relationToTenant,
        phone: phone.text,
        address: Address(
          street: _addressStreetController.text,
          complement: _addressComplementController.text.isEmpty
              ? null
              : _addressComplementController.text,
          zipCode: _addressZipCodeController.text,
          city: _addressCityController.text,
          codeQualite: _addressCodeQualite,
        ),
      );

      newGarantId = await _userServices
          .updateSingleGarant(
            garant: tempGarant,
            uid: widget.uid,
          )
          .then((result) => result.when(success: (v) => v, failure: (_) => null));
    }

    if (newGarantId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'enregistrement du garant"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Enregistre les documents associés
    for (final doc in documents) {
      if (doc.docType.isNotEmpty && doc.fileUrl?.isNotEmpty == true) {
        final newDocJustif = DocumentModel(
          extension: fileExtension,
          type: doc.docType,
          timeStamp: Timestamp.now(),
          documentPathRecto: doc.fileUrl!,
        );
        await docsRepository.setDocumentGarant(
          garantId: newGarantId,
          newDoc: newDocJustif,
          userId: widget.uid,
        );
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Garant et documents enregistrés")),
    );

    // Mets à jour le garant local avec l’ID Firestore
    setState(() {
      currentGarant = GuarantorInfo(
        id: newGarantId,
        email: mail.text,
        name: formattedName,
        surname: formattedSurname,
        birthday: birthdayValue!,
        sex: sex,
        nationality: _nationality,
        placeOfborn: formattedPlaceOfBorn,
        incomes: incomeEntries,
        jobIncomes: jobEntries,
        dependents: _dependents,
        familySituation: _familySituation,
        relationToTenant: _relationToTenant,
        phone: phone.text,
        address: Address(
          street: _addressStreetController.text,
          complement: _addressComplementController.text.isEmpty
              ? null
              : _addressComplementController.text,
          zipCode: _addressZipCodeController.text,
          city: _addressCityController.text,
          codeQualite: _addressCodeQualite,
        ),
      );

      documents.clear();
    });
    ref.invalidate(garantDocumentsProvider(
        (tenantUid: widget.uid, garantId: newGarantId)));
  }

  Future<void> _removeDoc(
    String url,
    String uid,
    String docId,
  ) async {
    await _storageServices.removeFileFromUrl(url);
    await docsRepository.deleteGarantDocuments(
      uid, widget.garant!.id!, docId, // <- L'ID récupéré depuis Firestore
    );
    ref.invalidate(garantDocumentsProvider(
        (tenantUid: widget.uid, garantId: widget.garant!.id!)));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Document supprimé avec succès")),
    );
  }

  void downloadImagePath(String downloadUrl, String extension) {
    setState(() {
      docUrl = downloadUrl;
      fileExtension = extension;
      appLog("FileEXTESION / $fileExtension");
      appLog("docURL / $docUrl");
    });
  }
}
