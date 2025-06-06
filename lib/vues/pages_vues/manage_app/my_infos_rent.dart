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
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/import_docs.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MyInfosRent extends StatefulWidget {
  final String uid;
  final Color color;
  final String? docId;

  const MyInfosRent({
    super.key,
    required this.uid,
    required this.color,
    this.docId,
  });

  @override
  State<MyInfosRent> createState() => _MyInfosRentState();
}

class _MyInfosRentState extends State<MyInfosRent> {
  final DataBasesUserServices _userServices = DataBasesUserServices();
  final DataBasesDocsServices dataBasesDocsServices = DataBasesDocsServices();
  final StorageServices _storageServices = StorageServices();
  UserInfo? tenantUser;
  bool isLoading = true;
  List<IncomeEntry> incomeEntries = [];
  List<JobEntry> jobEntries = [];
  Future<List<Map<String, dynamic>>>? _documentsFuture;
  String fileExtension = "";
  String docUrl = "";
  String contactType = "";

  DemandeLoc demande = DemandeLoc();
  // Liste des documents & justificatifs
  List<JustifDocument> documents = [];

  @override
  void initState() {
    super.initState();
    fetchTenantUser();
    _documentsFuture = fetchDocuments();
  }

  Future<void> fetchTenantUser() async {
    final user = await _userServices.getUserWithInfo(widget.uid);
    if (mounted) {
      setState(() {
        tenantUser = user;
        isLoading = false;
      });

      if (tenantUser != null) {
        jobEntries = List<JobEntry>.from(tenantUser!.jobIncomes ?? []);
        incomeEntries = List<IncomeEntry>.from(tenantUser!.incomes ?? []);
      }
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

    if (tenantUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Aucun locataire trouvé.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Mon dossier locataire", Colors.black87, SizeFont.h1.size),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.lotName(
              "Mon emploi actuel",
              Colors.black,
              SizeFont.h2.size,
            ),

            const SizedBox(height: 20),
            ...jobEntries.asMap().entries.map((entry) {
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
                          entryJobDate: job.entryJobDate);
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
                            entryJobDate: job.entryJobDate);
                      });
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
                        setState(() {
                          jobEntries[index] = JobEntry(
                              entryJobDate: Timestamp.fromDate(pickedDate),
                              typeContract: job.typeContract,
                              profession: job.profession);
                        });
                      }
                    },
                  ),
                  _removeJob("l'activité", index),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
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
              "Mes revenus",
              Colors.black,
              SizeFont.h2.size,
            ),
            const SizedBox(height: 20),

            // --- GESTION DES REVENUS (inchangée) ---
            ...incomeEntries.asMap().entries.map((entry) {
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
                          income.label.isEmpty
                              ? "Type de revenu"
                              : income.label,
                          false,
                          items: TenantList.incomesType(),
                          onValueChanged: (value) {
                            setState(() {
                              incomeEntries[index] = IncomeEntry(
                                  label: value, amount: income.amount);
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
                          controller:
                              TextEditingController(text: income.amount),
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
            }).toList(),

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

                  // Si le bloc est déjà uploadé, ne pas l’afficher
                  if (doc.isUploaded) return const SizedBox.shrink();

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
                          onDocumentUploaded: (downloadUrl, extension) async {
                            if (doc.docType.isNotEmpty) {
                              final newDocJustif = DocumentModel(
                                extension: extension,
                                type: doc.docType,
                                timeStamp: Timestamp.now(),
                                documentPathRecto: downloadUrl,
                              );
                              await dataBasesDocsServices.setDocumentTenant(
                                newDocJustif,
                                widget.uid,
                              );

                              setState(() {
                                doc.fileUrl = downloadUrl;
                                doc.isUploaded = true; // ✅ Masquer le bloc
                                _documentsFuture = fetchDocuments();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                }).toList(),
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
            const SizedBox(height: 50),
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
                  function: saveUserInfo,
                ),
                ButtonAdd(
                  color: Colors.transparent,
                  text: "Partager",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: widget.color,
                  borderColor: widget.color,
                  function: () => sendFile(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  shareFolder() {}

  sendFile(BuildContext context) async {
    if (widget.docId == null) {
      print("Erreur : docId est null !");
      return;
    } else {
      print("DOC ID : ${widget.docId}");
    }

    await showGuarantorSelectionDialog(context, tenantUser!.uid, widget.docId!);

    // List<String>? selectedGarantIds =
    //     selectedGarants.map((g) => g.id!).toList();
    // demande = DemandeLoc(
    //   timestamp: Timestamp.now(),
    //   tenantId: tenantUser!.uid,
    //   garantId: selectedGarantIds,
    // );

    // await FirebaseFirestore.instance
    //     .collection('User')
    //     .doc(tenantUser!.uid)
    //     .collection('demandes_loc')
    //     .add(demande.toJson());

    // print('DemandeLoc envoyée avec succès !');
  }

  void saveUserInfo() async {
    if (tenantUser == null) return;

    UserInfo updatedUser = UserInfo(
      uid: tenantUser!.uid,
      email: tenantUser!.email,
      name: tenantUser!.name,
      surname: tenantUser!.surname,
      pseudo: tenantUser!.pseudo,
      approved: tenantUser!.approved,
      profilPic: tenantUser!.profilPic ?? '',
      privacyPolicy: tenantUser!.privacyPolicy,
      birthday: tenantUser!.birthday,
      sex: tenantUser!.sex,
      nationality: tenantUser!.nationality,
      placeOfborn: tenantUser!.placeOfborn,
      incomes: incomeEntries,
      jobIncomes: jobEntries,
      dependent: tenantUser!.dependent,
      familySituation: tenantUser!.familySituation,
      phone: tenantUser!.phone,
    );

    bool success = await _userServices.updateUserInfo(updatedUser);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informations mises à jour avec succès")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour")),
      );
    }
    setState(() {
      _documentsFuture = fetchDocuments();
    });
  }

  Timestamp? _parseDate(String dateStr) {
    try {
      DateTime dt = DateFormat('dd/MM/yyyy').parse(dateStr);
      return Timestamp.fromDate(dt);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void addIncomeEntry() {
    setState(() {
      incomeEntries.add(IncomeEntry(label: '', amount: ''));
    });
  }

  void addJobEntry() {
    setState(() {
      jobEntries.add(JobEntry(
        typeContract: '',
        entryJobDate: null,
        profession: '',
      ));
    });
  }

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(widget.uid)
        .collection('documents')
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'document': DocumentModel.fromJson(doc.data()),
      };
    }).toList();
  }

  void downloadImagePath(String downloadUrl, String extension) {
    setState(() {
      docUrl = downloadUrl;
      fileExtension = extension;
      print("FileEXTESION / $fileExtension");
      print("docURL / $docUrl");
    });
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

  Widget _remove(String object, int index) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            incomeEntries.removeAt(index);
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

  Future<void> _removeDoc(
    String url,
    String uid,
    String docId,
  ) async {
    await _storageServices.removeFileFromUrl(url);
    await dataBasesDocsServices.deleteTenantDocument(
      userId: uid,
      documentId: docId, // <- L'ID récupéré depuis Firestore
    );
    setState(() {
      _documentsFuture = fetchDocuments();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Document supprimé avec succès")),
    );
  }

  Future<List<GuarantorInfo>> showGuarantorSelectionDialog(
      BuildContext context, String uid, String docId) async {
    List<GuarantorInfo> allGarants =
        await DataBasesUserServices.getGarants(uid, docId);
    List<String> selected = [];

    print('Garants disponibles:');
    allGarants.forEach((g) {
      print('Garant: ${g.name} ${g.surname} - ${g.email}');
    });

    return await showDialog<List<GuarantorInfo>>(
          context: context,
          builder: (context) {
            List<GuarantorInfo> selected = [];

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: MyTextStyle.lotName('Sélectionnez 2 garants',
                      Colors.black87, SizeFont.h1.size, FontWeight.bold),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: allGarants.map((g) {
                        bool isSelected = selected.contains(g);
                        return CheckboxListTile(
                          title: MyTextStyle.lotName(
                              '${g.name} ${g.surname}',
                              Colors.black87,
                              SizeFont.h3.size,
                              FontWeight.normal),
                          subtitle: Text(g.email),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (selected.length <= 1) {
                                  selected.add(g);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Vous ne pouvez sélectionner que 2 garants.'),
                                    duration: Duration(seconds: 2),
                                  ));
                                }
                              } else {
                                selected.remove(g);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, selected);
                        List<String>? selectedGarantIds =
                            selected.map((g) => g.id!).toList();

                        demande = DemandeLoc(
                          timestamp: Timestamp.now(),
                          tenantId: tenantUser!.uid,
                          garantId: selectedGarantIds,
                        );

                        // await FirebaseFirestore.instance
                        //     .collection('User')
                        //     .doc(tenantUser!.uid)
                        //     .collection('demandes_loc')
                        //     .add(demande.toJson());

                        print('DemandeLoc envoyée avec succès !');

                        await DataBasesUserServices.shareFile(demande, uid);
                      },
                      child: Text('Valider'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        [];
  }
}
