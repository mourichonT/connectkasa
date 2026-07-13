import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/job_entry.dart';
import 'package:konodal/controllers/features/justif_document.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/core/providers/docs_providers.dart';
import 'package:konodal/core/providers/docs_repository_provider.dart';
import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/docs_repository.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/controllers/features/income_entry.dart';
import 'package:konodal/models/enum/icons_extension.dart';
import 'package:konodal/models/enum/tenant_list.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:konodal/models/pages_models/document_model.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/import_docs.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:konodal/vues/widget_view/components/share_rent_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class MyInfosRent extends ConsumerStatefulWidget {
  final String uid;
  final Color color;

  const MyInfosRent({
    super.key,
    required this.uid,
    required this.color,
  });

  @override
  ConsumerState<MyInfosRent> createState() => _MyInfosRentState();
}

class _MyInfosRentState extends ConsumerState<MyInfosRent> {
  late final IUserRepository _userServices;
  late final IDocsRepository docsRepository;
  late final IStorageRepository _storageServices;
  UserInfo? tenantUser;
  bool isLoading = true;
  List<IncomeEntry> incomeEntries = [];
  List<JobEntry> jobEntries = [];
  // État d'ouverture des cartes d'activité : purement local (UI), jamais
  // persisté en base. Basé sur l'identité de l'objet (comme
  // ManageStructure/_expandedBuildings et MyGarantInfos/_expandedJobs) -
  // fonctionne car JobEntry est mutable (mutation en place, pas de
  // remplacement de l'objet à chaque modification).
  final Set<JobEntry> _expandedJobs = {};
  String fileExtension = "";
  String docUrl = "";
  String contactType = "";

  DemandeLoc demande = DemandeLoc();
  // Liste des documents & justificatifs
  List<JustifDocument> documents = [];

  @override
  void initState() {
    super.initState();
    _userServices = ref.read(userRepositoryProvider);
    docsRepository = ref.read(docsRepositoryProvider);
    _storageServices = ref.read(storageRepositoryProvider);
    fetchTenantUser();
  }

  Future<void> fetchTenantUser() async {
    final user = await _userServices
        .getUserWithInfo(widget.uid)
        .then((result) => result.when(success: (v) => v, failure: (_) => null));
    if (mounted) {
      setState(() {
        tenantUser = user;
        isLoading = false;
      });

      if (tenantUser != null) {
        jobEntries = List<JobEntry>.from(tenantUser!.jobIncomes);
        incomeEntries = List<IncomeEntry>.from(tenantUser!.incomes);
      }
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
            ..._buildJobSection(width),
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
                                  label: value,
                                  amount: incomeEntries[index].amount);
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
                            incomeEntries[index] = IncomeEntry(
                                label: incomeEntries[index].label,
                                amount: val);
                          },
                        ),
                      ),
                    ],
                  ),
                  _remove("le revenu", index),
                  const SizedBox(height: 10),
                ],
              );
            }),

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

            _buildDocumentsSection(),

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
                              await docsRepository.setDocumentTenant(
                                newDocJustif,
                                widget.uid,
                              );

                              setState(() {
                                doc.fileUrl = downloadUrl;
                                doc.isUploaded = true; // ✅ Masquer le bloc
                              });
                              ref.invalidate(
                                  tenantDocumentsProvider(widget.uid));
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                }),
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
          ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
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
            ),
          ),
        ],
      ),
    );
  }

  sendFile(BuildContext context) async {
    await ShareRentFolder.showGuarantorSelectionDialog(
        context, tenantUser!.uid);
  }

  void saveUserInfo() async {
    if (tenantUser == null) return;

    for (final job in jobEntries) {
      job.profession = capitalizeFirstLetter(job.profession);
    }

    UserInfo updatedUser = UserInfo(
      uid: tenantUser!.uid,
      email: tenantUser!.email,
      name: tenantUser!.name,
      surname: tenantUser!.surname,
      pseudo: tenantUser!.pseudo,
      isApproved: tenantUser!.isApproved,
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

    bool success = await _userServices
        .updateUserInfo(updatedUser)
        .then((result) => result.when(success: (v) => v, failure: (_) => false));

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informations mises à jour avec succès")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour")),
      );
    }
    ref.invalidate(tenantDocumentsProvider(widget.uid));
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
      final job = JobEntry(
        typeContract: '',
        entryJobDate: null,
        profession: '',
      );
      jobEntries.add(job);
      _expandedJobs.add(job);
    });
  }

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
                  CustomTextFieldWidget(
                    label: "Activité professionnelle",
                    controller: TextEditingController(text: job.profession),
                    isEditable: true,
                    onChanged: (val) => job.profession = val,
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

  Widget _buildDocumentsSection() {
    final documentsAsync = ref.watch(tenantDocumentsProvider(widget.uid));

    return documentsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
      data: (documentList) {
        if (documentList.isEmpty) {
          return const Center(child: Text('Aucun document trouvé.'));
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
                  : Image.asset('images/icon_extension/default.png'),
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
                            content:
                                Text("Impossible de télécharger le document"),
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
      },
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
    await docsRepository.deleteTenantDocument(
      userId: uid,
      documentId: docId, // <- L'ID récupéré depuis Firestore
    );
    ref.invalidate(tenantDocumentsProvider(widget.uid));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Document supprimé avec succès")),
    );
  }
}
