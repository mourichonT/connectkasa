import 'package:konodal/controllers/features/contact_features.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/core/providers/docs_providers.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/icons_extension.dart';
import 'package:konodal/models/enum/tenant_list.dart';
import 'package:konodal/models/pages_models/document_model.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/pages_vues/chat_page/chat_page.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:konodal/vues/widget_view/components/share_rent_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class TenantDetail extends ConsumerWidget {
  final UserInfo tenant;
  final String senderUid;
  final String? residenceId;
  // ID du lot occupé par ce locataire - nécessaire pour le révoquer de
  // manière scopée à ce seul lot (removeIdLocataire).
  final String? lotId;
  final String? demandeId;
  final Color color;
  final Function()? refreshUnseeCounter;
  // Rafraîchit la liste des locataires de ManagementTenant après une
  // révocation réussie (l'onglet "Actuels" doit perdre ce locataire,
  // l'onglet "Historique" doit le gagner).
  final Function()? refreshTenants;

  const TenantDetail(
      {super.key,
      this.refreshUnseeCounter,
      this.refreshTenants,
      required this.tenant,
      required this.color,
      required this.senderUid,
      this.residenceId,
      this.lotId,
      this.demandeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double width = MediaQuery.of(context).size.width;
    final bool isCurrentTenant =
        residenceId != null && residenceId!.isNotEmpty;
    return Scaffold(
      bottomSheet: Container(
        width: width,
        color: Theme.of(context)
            .indicatorColor, // Changez cette couleur selon vos besoins
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ButtonAdd(
              function: () async {
                if (isCurrentTenant) {
                  if (lotId == null || lotId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Impossible de révoquer : lot introuvable."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: MyTextStyle.lotName(
                          "Confirmer la révocation",
                          Colors.black87,
                          SizeFont.h2.size),
                      content: MyTextStyle.annonceDesc(
                          "Vous êtes sur le point de révoquer ${tenant.name} ${tenant.surname}, êtes-vous sûr de confirmer ? Cette action est définitive, le locataire n'aura plus accès à la résidence.",
                          SizeFont.h3.size,
                          5),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: MyTextStyle.lotName(
                              "Annuler",
                              Colors.black54,
                              SizeFont.h3.size,
                              FontWeight.normal),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: MyTextStyle.lotName(
                              "Révoquer",
                              Colors.red[800]!,
                              SizeFont.h3.size,
                              FontWeight.normal),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  if (!context.mounted) return;

                  final result = await ref
                      .read(lotRepositoryProvider)
                      .removeIdLocataire(residenceId!, lotId!, tenant.uid);
                  if (!context.mounted) return;
                  result.when(
                    success: (_) {
                      refreshTenants?.call();
                      Navigator.pop(context);
                    },
                    failure: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur lors de la révocation : $error"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  );
                } else {
                  await ShareRentFolder.showLotSelectionDialog(
                      context, senderUid, tenant.uid,
                      demandeId: demandeId);
                  // Sans ça, "Actuels" (nouveau locataire) et "Demande" (la
                  // demande acceptée est supprimée, cf. _addTenantToLot) de
                  // ManagementTenant ne se mettent à jour qu'après un
                  // rechargement complet de l'app.
                  refreshTenants?.call();
                  if (refreshUnseeCounter != null) {
                    refreshUnseeCounter!();
                  }
                }
              },
              color: isCurrentTenant
                  ? Colors.red[800]!
                  : Theme.of(context).primaryColor,
              icon: isCurrentTenant ? Icons.clear : Icons.add,
              text: isCurrentTenant ? "Revoquer" : "Ajouter",
              horizontal: 20,
              vertical: 10,
              size: SizeFont.h3.size,
            ),
            if (!isCurrentTenant)
              Visibility(
                child: ButtonAdd(
                  function: () async {
                    final reason = await _showRefusalReasonDialog(context);
                    if (reason == null) return; // annulé
                    if (!context.mounted) return;

                    await ref
                        .read(userRepositoryProvider)
                        .refuseDemande(
                          uid: senderUid,
                          demandeId: demandeId!,
                          reason: reason,
                        )
                        .then((result) =>
                            result.when(success: (_) {}, failure: (_) {}));
                    if (refreshUnseeCounter != null) {
                      refreshUnseeCounter!();
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  color: Colors.red[800]!,
                  icon: Icons.clear,
                  text: "Refuser",
                  horizontal: 20,
                  vertical: 10,
                  size: SizeFont.h3.size,
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations personnelles
              _buildSectionHeader("Informations personnelles"),

              lineToWrite(
                  Icons.cake,
                  "Date de naissance",
                  DateFormat('dd/MM/yyyy')
                      .format(tenant.birthday.toDate())),
              lineToWrite(Icons.flag, "Nationalité", tenant.nationality),
              lineToWrite(
                  Icons.diamond, "Situation", tenant.familySituation),
              if (!tenant.conjoint.isEmpty)
                lineToWrite(Icons.favorite, "Conjoint(e)",
                    "${tenant.conjoint.name} ${tenant.conjoint.surname}"
                        .trim()),
              for (final dependent in tenant.dependents)
                if (dependent.type.isNotEmpty)
                  lineToWrite(
                      Icons.favorite_outlined, dependent.type, dependent.count),
              if (tenant.address.city.isNotEmpty)
                lineToWrite(
                    Icons.home_outlined,
                    "Adresse",
                    "${tenant.address.street}"
                            "${tenant.address.complement?.isNotEmpty == true ? ', ${tenant.address.complement}' : ''}"
                            "\n${tenant.address.zipCode} ${tenant.address.city}"
                        .trim(),
                    wrapValue: true),

              //contact
              _buildSectionHeader("Contact locataire"),
              InkWell(
                onTap: () {
                  ContactFeatures.launchPhoneCall(tenant.phone);
                },
                child:
                    lineToWrite(Icons.phone, "Téléphone", tenant.phone),
              ),
              lineToWrite(Icons.email, "mail", tenant.email),
              if (residenceId != "")
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ButtonAdd(
                        function: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                residence: residenceId ?? '',
                                idUserFrom: senderUid,
                                idUserTo: tenant.uid,
                              ),
                            ),
                          );
                        },
                        borderColor: Theme.of(context).primaryColor,
                        color: Colors.white,
                        colorText: Theme.of(context).primaryColor,
                        icon: Icons.mail,
                        text: "Contacter",
                        horizontal: 20,
                        vertical: 5,
                        size: SizeFont.h3.size,
                      ),
                    ],
                  ),
                ),

              // Profil locataire
              _buildSectionHeader("Profil locataire"),
              if (tenant.jobIncomes.isEmpty)
                const Text("Aucune activité renseignée")
              else ...[
                for (int i = 0; i < tenant.jobIncomes.length; i++) ...[
                  lineToWrite(
                    Icons.work_rounded,
                    "Profession",
                    tenant.jobIncomes[i].profession,
                  ),
                  lineToWrite(
                    Icons.file_open,
                    "Type de contrat",
                    tenant.jobIncomes[i].typeContract,
                  ),
                  lineToWrite(
                    Icons.calendar_month,
                    "Date début contrat",
                    tenant.jobIncomes[i].entryJobDate != null
                        ? DateFormat('dd/MM/yyyy').format(
                            tenant.jobIncomes[i].entryJobDate!.toDate(),
                          )
                        : "Non renseignée",
                  ),
                  if (i <
                      tenant.jobIncomes.length -
                          1) // 👈 uniquement avant le dernier
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Divider(),
                    ),
                ]
              ],

              _buildSectionHeader("Revenus"),
              if (tenant.incomes.isEmpty)
                const Text("Aucun revenu renseigné")
              else ...[
                ...tenant.incomes.map((income) {
                  double amountDouble = double.tryParse(income.amount) ?? 0.0;
                  return lineToWrite(
                    null,
                    income.label,
                    "${amountDouble.toStringAsFixed(2)} €",
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Divider(),
                ),
                lineToWrite(
                  Icons.euro,
                  "Total des revenus",
                  "${tenant.incomes.map((e) => double.tryParse(e.amount) ?? 0.0).fold(0.0, (a, b) => a + b).toStringAsFixed(2)} €",
                ),
              ],

              _buildSectionHeader("Liste des documents & justificatifs"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: _buildGridSection(
                    ref.watch(tenantDocumentsProvider(tenant.uid))),
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modale demandant le motif de refus (liste fermée, non discriminatoire -
  /// cf. TenantList.motifsRefusLocation) avant de confirmer "Refuser".
  /// Retourne le motif choisi, ou null si annulé.
  Future<String?> _showRefusalReasonDialog(BuildContext context) {
    String reason = '';
    // Largeur explicite (pas de LayoutBuilder) : AlertDialog dimensionne son
    // content via IntrinsicWidth, incompatible avec LayoutBuilder - cf.
    // look_up_user.dart. 80 = insetPadding horizontal par défaut (40x2).
    final dropdownWidth = MediaQuery.of(context).size.width - 80;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: MyTextStyle.lotName(
              "Refuser la demande", Colors.black87, SizeFont.h2.size),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyTextStyle.postDesc(
                "Vous choisissez de refuser la location à ${tenant.name} "
                "${tenant.surname}, veuillez indiquer les motifs de ce refus.",
                SizeFont.h3.size,
                Colors.black54,
                fontweight: FontWeight.normal,
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 15),
              MyDropDownMenu(
                dropdownWidth,
                "Motif du refus",
                reason.isEmpty ? "Motif du refus" : reason,
                false,
                items: TenantList.motifsRefusLocation(),
                onValueChanged: (value) => setState(() => reason = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: MyTextStyle.lotName("Annuler", Colors.black54,
                  SizeFont.h3.size, FontWeight.normal),
            ),
            TextButton(
              onPressed: reason.isEmpty
                  ? null
                  : () => Navigator.pop(context, reason),
              child: MyTextStyle.lotName("Confirmer le refus",
                  Colors.red[800]!, SizeFont.h3.size, FontWeight.normal),
            ),
          ],
        );
      }),
    );
  }

  Widget lineToWrite(IconData? icon, String label, String value,
      {bool wrapValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment:
            wrapValue ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: Colors.black54,
            ),
          const SizedBox(width: 10),
          MyTextStyle.lotDesc(label, SizeFont.h3.size, FontStyle.normal,
              FontWeight.bold, Colors.black54),
          const SizedBox(width: 10),
          // Adresse (et tout autre champ potentiellement long) : Spacer +
          // Text sans contrainte de largeur ne wrap jamais (Row laisse le
          // Text prendre sa largeur intrinsèque) - Expanded lui donne une
          // largeur bornée pour que le retour à la ligne fonctionne.
          if (wrapValue)
            Expanded(
              child: MyTextStyle.lotDesc(
                  value,
                  SizeFont.h3.size,
                  FontStyle.normal,
                  FontWeight.normal,
                  Colors.black54,
                  TextAlign.right),
            )
          else ...[
            const Spacer(),
            MyTextStyle.lotDesc(value, SizeFont.h3.size, FontStyle.normal,
                FontWeight.normal, Colors.black54),
          ],
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

  Widget _buildGridSection(
      AsyncValue<List<Map<String, dynamic>>> documentsAsync) {
    return documentsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
      data: (documentList) {
        if (documentList.isEmpty) {
          return const Center(child: Text('Aucun document trouvé.'));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cartes par ligne
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3 / 2,
          ),
          itemCount: documentList.length,
          itemBuilder: (context, index) {
            final docMap = documentList[index];
            final DocumentModel doc = docMap['document'];

            final fileType = getFileType(doc.extension);

            return Card(
              elevation: 3,
              child: InkWell(
                onTap: () async {
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
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      fileType != null
                          ? SizedBox(width: 30, child: fileType.icon)
                          : Image.asset(
                              'images/icon_extension/default.png',
                              height: 20,
                            ),
                      MyTextStyle.postDesc(
                          doc.type, SizeFont.h3.size, Colors.black87,
                          fontweight: FontWeight.normal,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
