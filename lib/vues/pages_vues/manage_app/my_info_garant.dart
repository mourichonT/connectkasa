import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/job_entry.dart';
import 'package:connect_kasa/controllers/features/justif_document.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/controllers/features/income_entry.dart';
import 'package:connect_kasa/models/enum/icons_extension.dart';
import 'package:connect_kasa/models/enum/tenant_list.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/import_docs.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MyGarantInfos extends StatefulWidget {
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
  State<MyGarantInfos> createState() => _MyGarantInfosState();
}

class _MyGarantInfosState extends State<MyGarantInfos> {
  final DataBasesUserServices _userServices = DataBasesUserServices();
  final StorageServices _storageServices = StorageServices();
  final DataBasesDocsServices dataBasesDocsServices = DataBasesDocsServices();

  //Controllers
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController birthday = TextEditingController();
  TextEditingController birthdayController = TextEditingController();
  TextEditingController placeOfBorn = TextEditingController();
  TextEditingController nationality = TextEditingController();
  TextEditingController mail = TextEditingController();
  TextEditingController phone = TextEditingController();

  Timestamp? birthdayValue;
  String sex = "";
  String fileExtension = "";
  String docUrl = "";

  GuarantorInfo? currentGarant;
  GuarantorInfo? garantUser;
  bool isLoading = true;
  // Liste des documents & justificatifs
  List<JustifDocument> documents = [];
  List<IncomeEntry> incomeEntries = [];
  List<JobEntry> jobEntries = [];

  Future<List<Map<String, dynamic>>>? _documentsFuture;

  @override
  void initState() {
    super.initState();
    currentGarant = widget.garant;
    fetchGarantUser();
    if (widget.garant != null) {
      _documentsFuture = DataBasesDocsServices.fetchGarantDocuments(
          widget.uid, widget.garant!.id!);
    }
  }

  @override
  void dispose() {
    // Dispose des controllers
    name.dispose();
    surname.dispose();
    birthday.dispose();
    birthdayController.dispose();
    placeOfBorn.dispose();
    nationality.dispose();
    mail.dispose();
    phone.dispose();

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
      nationality.text = user.nationality;
      sex = user.sex;
      mail.text = user.email;
      phone.text = user.phone;

      print("Incomes length: ${incomeEntries.length}");
      print("Job incomes length: ${jobEntries.length}");
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
        dependent: 0,
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
        body: Center(child: CircularProgressIndicator()),
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
                  child: CustomTextFieldWidget(
                    label: "Nationnalité",
                    text: nationality.text,
                    controller: nationality,
                    isEditable: true,
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
            CustomTextFieldWidget(
              keyboardType: TextInputType.phone,
              label: "Téléphone principal",
              text: phone.text,
              controller: phone,
              isEditable: true,
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
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _documentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun document trouvé.'));
                } else {
                  final documentList = snapshot.data!;
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
                            : Image.asset('images/icon_extension/default.png'),
                        title: Text(doc.type ?? ""),
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
                                    doc.documentPathRecto, widget.uid, docId)),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
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
                              _documentsFuture =
                                  DataBasesDocsServices.fetchGarantDocuments(
                                      widget.uid, widget.garant!.id!);
                            });
                            downloadImagePath(downloadUrl,
                                extension); // Appel de ta fonction existante
                          },
                        )
                      ],
                    ),
                  );
                }).toList(),
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
                        DataBasesUserServices.deleteGarant(
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextFieldWidget(
            label: "Activité professionnelle",
            controller: TextEditingController(text: job.profession),
            isEditable: true,
            onChanged: (val) {
              jobEntries[index] = JobEntry(
                profession: val,
                typeContract: job.typeContract,
                entryJobDate: job.entryJobDate,
              );
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
              setState(() {
                jobEntries[index] = JobEntry(
                  typeContract: value,
                  profession: job.profession,
                  entryJobDate: job.entryJobDate,
                );
                DataBasesDocsServices.fetchGarantDocuments(
                    widget.uid, widget.garant!.id!);
              });
            },
          ),
          const SizedBox(height: 10),
          CustomTextFieldWidget(
            label: "Date d'entrée",
            controller: TextEditingController(
              text: job.entryJobDate != null
                  ? DateFormat('dd/MM/yyyy').format(job.entryJobDate!.toDate())
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
                setState(() {
                  jobEntries[index] = JobEntry(
                    entryJobDate: Timestamp.fromDate(pickedDate),
                    typeContract: job.typeContract,
                    profession: job.profession,
                  );
                });
              }
            },
          ),
          _removeJob("l'activité", index),
          const SizedBox(height: 10),
        ],
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
                flex: 2,
                child: MyDropDownMenu(
                  width,
                  height: 90,
                  "Type de revenu",
                  income.label.isEmpty ? "Type de revenu" : income.label,
                  false,
                  items: TenantList.incomesType(),
                  onValueChanged: (value) {
                    setState(() {
                      incomeEntries[index] =
                          IncomeEntry(label: value, amount: income.amount);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: CustomTextFieldWidget(
                  keyboardType: TextInputType.number,
                  label: "Montant",
                  controller: TextEditingController(text: income.amount),
                  isEditable: true,
                  onChanged: (val) {
                    incomeEntries[index] =
                        IncomeEntry(label: income.label, amount: val);
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
      jobEntries
          .add(JobEntry(profession: "", typeContract: "", entryJobDate: null));
    });
  }

  void saveGarantInfo() async {
    FocusScope.of(context).unfocus();

    // ✅ Vérification des champs obligatoires
    if (name.text.isEmpty ||
        surname.text.isEmpty ||
        mail.text.isEmpty ||
        birthdayValue == null ||
        sex.isEmpty ||
        nationality.text.isEmpty ||
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

    GuarantorInfo newGarant = GuarantorInfo(
      email: mail.text,
      name: name.text,
      surname: surname.text,
      birthday: birthdayValue!,
      sex: sex,
      nationality: nationality.text,
      placeOfborn: placeOfBorn.text,
      incomes: incomeEntries,
      jobIncomes: jobEntries,
      dependent: 0,
      familySituation: '',
      phone: phone.text,
    );

    String? newGarantId;

    if (currentGarant != null) {
      // 🔁 Mise à jour d’un garant existant
      newGarantId = await DataBasesUserServices.updateSingleGarant(
        garant: newGarant,
        uid: widget.uid,
        garantDocId: currentGarant!.id!,
      );
    } else {
      // ➕ Création d’un nouveau garant
      newGarantId = await DataBasesUserServices.updateSingleGarant(
        garant: newGarant,
        uid: widget.uid,
      );
    }

    if (newGarantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'enregistrement du garant"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Ajout des documents justificatifs
    for (final doc in documents) {
      if (doc.docType.isNotEmpty && doc.fileUrl?.isNotEmpty == true) {
        final newDocJustif = DocumentModel(
          extension: fileExtension,
          type: doc.docType,
          timeStamp: Timestamp.now(),
          documentPathRecto: doc.fileUrl!,
        );
        await dataBasesDocsServices.setDocumentGarant(
          garantId: newGarantId,
          newDoc: newDocJustif,
          userId: widget.uid,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Garant et documents enregistrés")),
    );

    // ✅ Met à jour le garant local et réinitialise l'état du bloc
    setState(() {
      if (newGarantId != null) {
        currentGarant = newGarant.copyWith(id: newGarantId);
      }

      _documentsFuture = DataBasesDocsServices.fetchGarantDocuments(
        widget.uid,
        newGarantId!,
      );
      documents.clear();
    });
  }

  Future<void> _removeDoc(
    String url,
    String uid,
    String docId,
  ) async {
    await _storageServices.removeFileFromUrl(url);
    await dataBasesDocsServices.deleteGarantDocuments(
      uid, widget.garant!.id!, docId, // <- L'ID récupéré depuis Firestore
    );
    setState(() {
      _documentsFuture = DataBasesDocsServices.fetchGarantDocuments(
          widget.uid, widget.garant!.id!);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Document supprimé avec succès")),
    );
  }

  void downloadImagePath(String downloadUrl, String extension) {
    setState(() {
      docUrl = downloadUrl;
      fileExtension = extension;
      print("FileEXTESION / $fileExtension");
      print("docURL / $docUrl");
    });
  }
}
