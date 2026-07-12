import 'package:konodal/core/repositories/firestore_docs_repository.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/firestore_storage_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/icons_extension.dart';
import 'package:konodal/models/pages_models/document_model.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/pages_vues/docs_page/add_docs_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

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
  final FirestoreDocsRepository docsRepository = FirestoreDocsRepository();
  final FirestoreStorageRepository _storageServices = FirestoreStorageRepository();
  late Future<List<Map<String, dynamic>>> _allDocsCopro;
  late Future<List<Map<String, dynamic>>> _allDocsLot;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _allDocsCopro = _fetchDocsCopro();
    _allDocsLot = _fetchDocsLot();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<List<Map<String, dynamic>>> _fetchDocsCopro() {
    return docsRepository
        .getAllDocsWithId(widget.lotSelected.residenceId)
        .then((result) =>
            result.when(success: (docs) => docs, failure: (error) => throw error));
  }

  Future<List<Map<String, dynamic>>> _fetchDocsLot() {
    return docsRepository
        .getDocByUser(widget.uid, widget.lotSelected.id!)
        .then((result) =>
            result.when(success: (docs) => docs, failure: (error) => throw error));
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
                            function: () async {
                              await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => AddDocsForm(
                                            lotSelected: widget.lotSelected,
                                            uid: widget.uid,
                                            isDocCopro: true,
                                          )));
                              // Rafraîchit la liste au retour du formulaire,
                              // sinon le document ajouté n'apparaît pas tant
                              // que l'écran n'est pas rechargé.
                              if (mounted) {
                                setState(() {
                                  _allDocsCopro = _fetchDocsCopro();
                                });
                              }
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
                                child: AppLoader());
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
                                      if (!context.mounted) return;
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
                                              if (!context.mounted) return;
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
                                                  title: MyTextStyle.lotName(
                                                      'Confirmer la suppression',
                                                      Colors.black87,
                                                      SizeFont.h2.size),
                                                  content: MyTextStyle
                                                      .annonceDesc(
                                                          'Souhaitez-vous vraiment supprimer ce document ?',
                                                          SizeFont.h3.size,
                                                          3),
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
                                                final result =
                                                    await docsRepository
                                                        .deleteDocument(
                                                  lotId:
                                                      widget.lotSelected.id,
                                                  documentId: docId,
                                                  residenceId: widget
                                                      .lotSelected.residenceId,
                                                  documentType: doc.extension ??
                                                      'unknown',
                                                  isCopro: true,
                                                );
                                                if (!mounted) return;
                                                result.when(
                                                  success: (_) {},
                                                  failure: (error) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        backgroundColor:
                                                            Colors.red,
                                                        content: Text(
                                                            'Erreur lors de la suppression : $error'),
                                                      ),
                                                    );
                                                  },
                                                );
                                                if (mounted) {
                                                  setState(() {
                                                    _allDocsCopro =
                                                        _fetchDocsCopro();
                                                  });
                                                }
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
                            function: () async {
                              await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => AddDocsForm(
                                            lotSelected: widget.lotSelected,
                                            uid: widget.uid,
                                            isDocCopro: false,
                                          )));
                              if (mounted) {
                                setState(() {
                                  _allDocsLot = _fetchDocsLot();
                                });
                              }
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
                                child: AppLoader());
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
                                      if (!context.mounted) return;
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
                                              if (!context.mounted) return;
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
                                                  title: MyTextStyle.lotName(
                                                      'Confirmer la suppression',
                                                      Colors.black87,
                                                      SizeFont.h2.size),
                                                  content: MyTextStyle
                                                      .annonceDesc(
                                                          'Souhaitez-vous vraiment supprimer ce document ?',
                                                          SizeFont.h3.size,
                                                          3),
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
                                                // Documents déposés avant
                                                // l'ajout du champ
                                                // destinataire : on ne
                                                // connaît que sa propre
                                                // copie, faute de mieux.
                                                final recipients =
                                                    (docPerso.destinataire !=
                                                                null &&
                                                            docPerso
                                                                .destinataire!
                                                                .isNotEmpty)
                                                        ? docPerso
                                                            .destinataire!
                                                        : [widget.uid];
                                                final result =
                                                    await docsRepository
                                                        .deleteDocument(
                                                  recipientUids: recipients,
                                                  lotId:
                                                      widget.lotSelected.id,
                                                  documentId: docId,
                                                  residenceId: widget
                                                      .lotSelected.residenceId,
                                                  documentType:
                                                      docPerso.extension ??
                                                          'unknown',
                                                  isCopro: false,
                                                );
                                                if (!mounted) return;
                                                result.when(
                                                  success: (_) {},
                                                  failure: (error) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        backgroundColor:
                                                            Colors.red,
                                                        content: Text(
                                                            'Erreur lors de la suppression : $error'),
                                                      ),
                                                    );
                                                  },
                                                );
                                                if (mounted) {
                                                  setState(() {
                                                    _allDocsLot =
                                                        _fetchDocsLot();
                                                  });
                                                }
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
