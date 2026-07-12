import 'package:connect_kasa/controllers/features/contact_features.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/core/providers/docs_repository_provider.dart';
import 'package:connect_kasa/core/providers/garant_providers.dart';
import 'package:connect_kasa/core/providers/storage_repository_provider.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/icons_extension.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connect_kasa/vues/widget_view/components/app_loader.dart';

class GuarantorDetail extends ConsumerStatefulWidget {
  final String garantid;
  final String tenantUid;

  const GuarantorDetail({
    super.key,
    required this.garantid,
    required this.tenantUid,
  });

  @override
  ConsumerState<GuarantorDetail> createState() => GuarantorDetailState();
}

class GuarantorDetailState extends ConsumerState<GuarantorDetail> {
  late final ({String tenantUid, String garantId}) _garantArgs;

  @override
  void initState() {
    super.initState();
    _garantArgs =
        (tenantUid: widget.tenantUid, garantId: widget.garantid);
  }

  @override
  Widget build(BuildContext context) {
    final garantAsync = ref.watch(uniqueGarantProvider(_garantArgs));

    return Scaffold(
      body: garantAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) =>
            Center(child: Text('Erreur : $error')),
        data: (g) {
          if (g == null) {
            return const Center(child: Text("Aucun garant trouvé."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Informations personnelles"),
                lineToWrite(Icons.person, "Nom", "${g.name} ${g.surname}"),
                lineToWrite(Icons.cake, "Date de naissance",
                    DateFormat('dd/MM/yyyy').format(g.birthday.toDate())),
                lineToWrite(Icons.flag, "Nationalité", g.nationality),
                lineToWrite(Icons.diamond, "Situation", g.familySituation),
                if (g.dependent != 0)
                  lineToWrite(Icons.favorite_outlined, "Personne à charge",
                      g.dependent.toString()),
                _buildSectionHeader("Contact du garant"),
                InkWell(
                  onTap: () => ContactFeatures.launchPhoneCall(g.phone),
                  child: lineToWrite(Icons.phone, "Téléphone", g.phone),
                ),
                lineToWrite(Icons.email, "Mail", g.email),
                _buildSectionHeader("Activités & emplois"),
                if (g.jobIncomes.isEmpty)
                  const Text("Aucune activité renseignée")
                else ...[
                  for (int i = 0; i < g.jobIncomes.length; i++) ...[
                    lineToWrite(Icons.work_rounded, "Profession",
                        g.jobIncomes[i].profession),
                    lineToWrite(Icons.file_open, "Type de contrat",
                        g.jobIncomes[i].typeContract),
                    lineToWrite(
                        Icons.calendar_month,
                        "Date début contrat",
                        DateFormat('dd/MM/yyyy')
                            .format(g.jobIncomes[i].entryJobDate!.toDate())),
                    if (i < g.jobIncomes.length - 1)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Divider(),
                      ),
                  ],
                ],
                _buildSectionHeader("Revenus"),
                if (g.incomes.isEmpty)
                  const Text("Aucun revenu renseigné")
                else ...[
                  ...g.incomes.map((income) {
                    double amount = double.tryParse(income.amount) ?? 0.0;
                    return lineToWrite(
                      null,
                      income.label,
                      "${amount.toStringAsFixed(2)} €",
                    );
                  }).toList(),
                  const Divider(),
                  lineToWrite(Icons.euro, "Total des revenus",
                      "${g.incomes.map((e) => double.tryParse(e.amount) ?? 0.0).fold(0.0, (a, b) => a + b).toStringAsFixed(2)} €"),
                ],
                _buildSectionHeader("Liste des documents & justificatifs"),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: _buildGridSection(
                      ref.watch(garantDocumentsProvider(_garantArgs))),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget lineToWrite(IconData? icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon,
              color: Colors.black54,
            ),
          const SizedBox(width: 10),
          MyTextStyle.lotDesc(label, SizeFont.h3.size, FontStyle.normal,
              FontWeight.bold, Colors.black54),
          const Spacer(),
          MyTextStyle.lotDesc(value, SizeFont.h3.size, FontStyle.normal,
              FontWeight.normal, Colors.black54),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: MyTextStyle.lotDesc(
          title, SizeFont.h2.size, FontStyle.normal, FontWeight.bold),
    );
  }

  Widget _buildGridSection(AsyncValue<List<Map<String, dynamic>>> documentsAsync) {
    return documentsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
      data: (documentList) {
        if (documentList.isEmpty) {
          return const Center(child: Text('Aucun document trouvéICI.'));
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
                          doc.documentPathRecto, widget.tenantUid, docId)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeDoc(
    String url,
    String uid,
    String docId,
  ) async {
    await ref.read(storageRepositoryProvider).removeFileFromUrl(url);
    await ref
        .read(docsRepositoryProvider)
        .deleteGarantDocuments(uid, widget.garantid, docId);
    ref.invalidate(garantDocumentsProvider(_garantArgs));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Document supprimé avec succès")),
    );
  }
}
