import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/contact_features.dart';
import 'package:connect_kasa/controllers/handlers/exportpdfhttp.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/icons_extension.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
//import 'package:connect_kasa/vues/components/locascore_header.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GuarantorDetail extends StatefulWidget {
  final GuarantorInfo garant;

  const GuarantorDetail({
    super.key,
    required this.garant,
  });

  @override
  State<StatefulWidget> createState() => GuarantorDetailState();
}

class GuarantorDetailState extends State<GuarantorDetail> {
  Future<List<Map<String, dynamic>>>? _documentsFuture;
  final DataBasesDocsServices dataBasesDocsServices = DataBasesDocsServices();
  final StorageServices _storageServices = StorageServices();
  @override
  void initState() {
    super.initState();
    _documentsFuture = fetchDocuments();
  }

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(widget.garant.id)
        .collection('documents')
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'document': DocumentModel.fromJson(doc.data()),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations personnelles
              _buildSectionHeader("Informations personnelles"),
              lineToWrite(Icons.cake, "Nom",
                  " ${widget.garant.name} ${widget.garant.surname}"),
              lineToWrite(
                  Icons.cake,
                  "Date de naissance",
                  DateFormat('dd/MM/yyyy')
                      .format(widget.garant.birthday.toDate())),
              lineToWrite(Icons.flag, "Nationalité", widget.garant.nationality),
              lineToWrite(
                  Icons.diamond, "Situation", widget.garant.familySituation),
              if (widget.garant.dependent != 0)
                lineToWrite(Icons.favorite_outlined, "Personne à charge",
                    widget.garant.dependent.toString()),

              //contact
              _buildSectionHeader("Contact du garant"),
              InkWell(
                onTap: () {
                  ContactFeatures.launchPhoneCall(widget.garant.phone);
                },
                child:
                    lineToWrite(Icons.phone, "Téléphone", widget.garant.phone),
              ),
              lineToWrite(Icons.email, "mail", widget.garant.email),

              // Profil locataire
              _buildSectionHeader("Activités & emplois"),
              if (widget.garant.jobIncomes.isEmpty)
                const Text("Aucune activité renseignée")
              else ...[
                for (int i = 0; i < widget.garant.jobIncomes.length; i++) ...[
                  lineToWrite(
                    Icons.work_rounded,
                    "Profession",
                    widget.garant.jobIncomes[i].profession,
                  ),
                  lineToWrite(
                    Icons.file_open,
                    "Type de contrat",
                    widget.garant.jobIncomes[i].typeContract,
                  ),
                  lineToWrite(
                    Icons.calendar_month,
                    "Date début contrat",
                    DateFormat('dd/MM/yyyy').format(
                      widget.garant.jobIncomes[i].entryJobDate!.toDate(),
                    ),
                  ),
                  if (i <
                      widget.garant.jobIncomes.length -
                          1) // 👈 uniquement avant le dernier
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Divider(),
                    ),
                ]
              ],

              _buildSectionHeader("Revenus"),
              if (widget.garant.incomes.isEmpty)
                const Text("Aucun revenu renseigné")
              else ...[
                ...widget.garant.incomes.map((income) {
                  double amountDouble = double.tryParse(income.amount) ?? 0.0;
                  return lineToWrite(
                    null,
                    income.label,
                    "${amountDouble.toStringAsFixed(2)} €",
                  );
                }).toList(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Divider(),
                ),
                lineToWrite(
                  Icons.euro,
                  "Total des revenus",
                  "${widget.garant.incomes.map((e) => double.tryParse(e.amount) ?? 0.0).fold(0.0, (a, b) => a + b).toStringAsFixed(2)} €",
                ),
              ],

              _buildSectionHeader("Liste des documents & justificatifs"),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: _buildGridSection(),
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

  Widget _buildGridSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
              final String docId = docMap['id'];
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
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        fileType != null
                            ? Container(width: 30, child: fileType.icon)
                            : Image.asset(
                                'images/icon_extension/default.png',
                                height: 30,
                              ),
                        Text(
                          doc.type ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
