import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/icons_extension.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/docs_page/add_docs_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MydocsPageView extends StatefulWidget {
  final Lot lotSelected;

  final String uid;
  final Color colorStatut;
  final bool isCsMember;

  const MydocsPageView(
      {super.key,
      required this.uid,
      required this.colorStatut,
      required this.lotSelected,
      required this.isCsMember});

  @override
  State<StatefulWidget> createState() => MydocsPageViewState();
}

class MydocsPageViewState extends State<MydocsPageView>
    with SingleTickerProviderStateMixin {
  final DataBasesDocsServices docsServices = DataBasesDocsServices();
  final StorageServices _storageServices = StorageServices();
  late Future<List<Map<String, dynamic>>> _allDocsCopro;
  late Future<List<Map<String, dynamic>>> _allDocsLot;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _allDocsCopro =
        docsServices.getAllDocsWithId(widget.lotSelected.residenceId);
    _allDocsLot = docsServices.getDocByUser(
      widget.uid,
      "${widget.lotSelected.residenceData['id']}-${widget.lotSelected.refLot}",
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          TabBar.secondary(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Copropriété'),
              Tab(text: 'Individuel'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    Visibility(
                      visible: widget.isCsMember,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ButtonAdd(
                            function: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => AddDocsForm(
                                            lotSelected: widget.lotSelected,
                                            uid: widget.uid,
                                            isDocCopro: true,
                                          )));
                            },
                            color: widget.colorStatut,
                            icon: Icons.add,
                            text: 'Ajouter un document',
                            horizontal: 10,
                            vertical: 10,
                            size: SizeFont.h3.size),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _allDocsCopro,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Erreur : ${snapshot.error}');
                          } else {
                            List<Map<String, dynamic>> allDocs = snapshot.data!;
                            return ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              itemCount: allDocs.length,
                              itemBuilder: (context, index) {
                                final doc =
                                    allDocs[index]['data'] as DocumentModel;
                                final docId = allDocs[index]['id'] as String;

                                IconsExtension? fileType =
                                    getFileType(doc.extension);

                                return GestureDetector(
                                  onTap: () async {
                                    final url =
                                        Uri.parse(doc.documentPathRecto);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Le document ne peut pas être téléchargé.',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: ListTile(
                                    leading: fileType != null
                                        ? fileType.icon
                                        : Image.asset(
                                            'images/icon_extension/default.png'),
                                    title:
                                        Text(doc.name ?? 'Document sans nom'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.download_rounded),
                                          onPressed: () async {
                                            final url = Uri.parse(
                                                doc.documentPathRecto);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                    'Le document ne peut pas être téléchargé.',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        Visibility(
                                          visible: widget.isCsMember,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Confirmer la suppression'),
                                                  content: const Text(
                                                      'Souhaitez-vous vraiment supprimer ce document ?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Annuler'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                          'Supprimer'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await _storageServices
                                                    .removeFileFromUrl(
                                                        doc.documentPathRecto);
                                                await docsServices
                                                    .deleteDocument(
                                                  lotId:
                                                      "${widget.lotSelected.residenceData['id']}-${widget.lotSelected.refLot}",
                                                  documentId: docId,
                                                  residenceId: widget
                                                      .lotSelected.residenceId,
                                                  documentType: doc.extension ??
                                                      'unknown',
                                                  isCopro: true,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(thickness: 0.4),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Visibility(
                      visible: widget.lotSelected.idProprietaire!
                          .contains(widget.uid),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ButtonAdd(
                            function: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => AddDocsForm(
                                            lotSelected: widget.lotSelected,
                                            uid: widget.uid,
                                            isDocCopro: false,
                                          )));
                            },
                            color: widget.colorStatut,
                            icon: Icons.add,
                            text: 'Déposer un document',
                            horizontal: 10,
                            vertical: 10,
                            size: SizeFont.h3.size),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _allDocsLot,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('Aucun document trouvé.'));
                          } else {
                            List<Map<String, dynamic>> allDocsPerso =
                                snapshot.data!;

                            return ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              itemCount: allDocsPerso.length,
                              itemBuilder: (context, index) {
                                final docMap = allDocsPerso[index];
                                final DocumentModel docPerso = docMap['data'];
                                final String docId = docMap['id'];
                                IconsExtension? fileType =
                                    getFileType(docPerso.extension);

                                return GestureDetector(
                                  onTap: () async {
                                    final url =
                                        Uri.parse(docPerso.documentPathRecto);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Le document ne peut pas être téléchargé.',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: ListTile(
                                    leading: fileType != null
                                        ? fileType.icon
                                        : Image.asset(
                                            'images/icon_extension/default.png'),
                                    title: Text(
                                        docPerso.name ?? "Document sans nom"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.download_rounded),
                                          onPressed: () async {
                                            final url = Uri.parse(
                                                docPerso.documentPathRecto);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                    'Le document ne peut pas être téléchargé.',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        Visibility(
                                          visible: widget
                                              .lotSelected.idProprietaire!
                                              .contains(widget.uid),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Confirmer la suppression'),
                                                  content: const Text(
                                                      'Souhaitez-vous vraiment supprimer ce document ?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Annuler'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                          'Supprimer'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await _storageServices
                                                    .removeFileFromUrl(docPerso
                                                        .documentPathRecto);
                                                await docsServices
                                                    .deleteDocument(
                                                  userIdsMatrix: [
                                                    widget.lotSelected
                                                        .idLocataire!,
                                                    widget.lotSelected
                                                        .idProprietaire!
                                                  ],
                                                  lotId:
                                                      "${widget.lotSelected.residenceData['id']}-${widget.lotSelected.refLot}",
                                                  documentId: docId,
                                                  residenceId: widget
                                                      .lotSelected.residenceId,
                                                  documentType:
                                                      docPerso.extension ??
                                                          'unknown',
                                                  isCopro: false,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(thickness: 0.4),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Function to determine the file type
  IconsExtension? getFileType(String? extension) {
    switch (extension) {
      case 'doc':
        return IconsExtension.doc;
      case 'pdf':
        return IconsExtension.pdf;
      case 'jpg':
        return IconsExtension.jpg;
      case 'png':
        return IconsExtension.png;
      case 'xls':
        return IconsExtension.xls;
      case 'zip':
        return IconsExtension.zip;
      case 'mp3':
        return IconsExtension.mp3;
      default:
        return null; // Handle unknown extensions
    }
  }
}
