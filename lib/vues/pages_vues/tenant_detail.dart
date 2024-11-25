import 'package:connect_kasa/controllers/features/contact_features.dart';
import 'package:connect_kasa/controllers/features/exportpdfhttp.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/components/locascore_header.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class TenantDetail extends StatefulWidget {
  final UserInfo tenant;
  final String senderUid;
  final String residenceId;
  final Color color;

  const TenantDetail({super.key, required this.tenant, required this.color, required this.senderUid, required this.residenceId});

  @override
  State<StatefulWidget> createState() => TenantDetailState();
}

class TenantDetailState extends State<TenantDetail> {

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomSheet: Container(
        width: width,
  color: Theme.of(context).indicatorColor, // Changez cette couleur selon vos besoins
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Container(
        width: 150,
        child: ButtonAdd(
          function: () {
          },
          color: Colors.red,
          icon: Icons.clear,
          text: "Revoquer",
          horizontal: 20,
          vertical: 5,
          size: SizeFont.h3.size,
        ),
      ),
      Container(
        width: 150,
        child: ButtonAdd(
          function: () {
            Exportpdfhttp.ExportLocaScore(context,widget.tenant);
          },
          color: Theme.of(context).primaryColor,
          icon: Icons.download,
          text: "Télécharger",
          horizontal: 20,
          vertical: 5,
          size: SizeFont.h3.size,
        ),
      ),
    ],
  ),
),
      appBar: AppBar(
        title: MyTextStyle.lotName("", Colors.black87, SizeFont.h1.size),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profil section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfilTile(widget.tenant.uid, 40, 36, 40, false),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  MyTextStyle.lotName(
                                      widget.tenant.name,
                                      Colors.black87,
                                      SizeFont.h1.size),
                                  const SizedBox(width: 5),
                                  MyTextStyle.lotName(
                                      widget.tenant.surname,
                                      Colors.black87,
                                      SizeFont.h1.size),
                                ],
                              ),
                              MyTextStyle.lotDesc(widget.tenant.pseudo ?? "",
                                  SizeFont.h3.size, FontStyle.italic),
                            ],
                          ),
                        ),
                        // Stats section
                        Column(
                          children: [
                            _buildStatBox("7", "Évaluations"),
                            const SizedBox(height: 10),
                            _buildStatBox("4.5", "LocaScore", withStar: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

               Padding(
                 padding: const EdgeInsets.only(top: 20, bottom: 10),
                 child: LocascoreHeader(),
               ),


              // Informations personnelles
              _buildSectionHeader("Informations personnelles"),
              lineToWrite(Icons.numbers, "Référence Utilisateur",
                  widget.tenant.uid),
              lineToWrite(Icons.cake, "Date de naissance",
                  DateFormat('dd/MM/yyyy').format(widget.tenant.birthday.toDate())),
              lineToWrite(Icons.flag, "Nationalité", widget.tenant.nationality),
              lineToWrite(Icons.diamond, "Situation", widget.tenant.familySituation),
              if (widget.tenant.dependent != 0)
                lineToWrite(Icons.diamond, "Personne à charge",
                    widget.tenant.dependent.toString()),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Divider(),
              ),
              //contact
              _buildSectionHeader("Contact locataire"),
               InkWell(
                onTap: () {
                   ContactFeatures.launchPhoneCall(widget.tenant.phone);
                },
                 child: lineToWrite(Icons.phone, "Téléphone",
                    widget.tenant.phone),
               ),
              lineToWrite(Icons.email, "mail", widget.tenant.email),
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
                              residence: widget.residenceId,
                              idUserFrom: widget.senderUid,
                              idUserTo: widget.tenant.uid,
                            ),
                          ),
                        );
                      },
                      borderColor: Theme.of(context).primaryColor ,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Divider(),
              ),

              // Profil locataire
              _buildSectionHeader("Profil locataire"),
              lineToWrite(Icons.work_rounded, "Profession", widget.tenant.profession??""),
              lineToWrite(Icons.file_open, "Type de contrat", widget.tenant.typeContract),
              lineToWrite(Icons.calendar_month, "Date début contrat",  DateFormat('dd/MM/yyyy').format(widget.tenant.entryJobDate!.toDate())),
              lineToWrite(Icons.euro, "Salaire net", widget.tenant.salary),
              if (widget.tenant.amountAdditionalRevenu.isNotEmpty)
                lineToWrite(Icons.euro, "Revenu complémentaire",
                    widget.tenant.amountAdditionalRevenu),
              if (widget.tenant.amountHousingAllowance.isNotEmpty)
                lineToWrite(Icons.euro, "Allocation logement",
                    widget.tenant.amountHousingAllowance),
              if (widget.tenant.amountFamilyAllowance.isNotEmpty)
                lineToWrite(Icons.euro, "Allocations familiales",
                    widget.tenant.amountFamilyAllowance),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: const Divider(),
              ),
              _buildGridSection(),
              SizedBox(height: 50,),
            ],
          ),
        ),
      ),
    );
  }

  Widget lineToWrite(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          MyTextStyle.lotDesc(label, SizeFont.h3.size, FontStyle.normal, FontWeight.bold),
          const Spacer(),
          MyTextStyle.lotDesc(value, SizeFont.h3.size, FontStyle.normal,),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, {bool withStar = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: SizeFont.h3.size, fontWeight: FontWeight.bold),
              ),
              if (withStar) const Icon(Icons.star_rate_rounded, color: Colors.amber),
            ],
          ),
          MyTextStyle.lotDesc(label, SizeFont.para.size, FontStyle.italic),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MyTextStyle.lotDesc(title, SizeFont.h2.size, FontStyle.normal, FontWeight.bold),
    );
  }


  Widget _buildGridSection() {
  // Exemple de données pour les cartes
  final List<Map<String, String>> cardData = [
    {"title": "Card 1", "subtitle": "Subtitle 1"},
    {"title": "Card 2", "subtitle": "Subtitle 2"},
    {"title": "Card 3", "subtitle": "Subtitle 3"},
    {"title": "Card 4", "subtitle": "Subtitle 4"},
    {"title": "Card 5", "subtitle": "Subtitle 5"},
    {"title": "Card 6", "subtitle": "Subtitle 6"},
  ];

  return GridView.builder(
    shrinkWrap: true, // Important pour éviter des conflits de hauteur dans le `SingleChildScrollView`
    physics: const NeverScrollableScrollPhysics(), // Désactive le défilement interne du `GridView`
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // Nombre de colonnes
      crossAxisSpacing: 10, // Espacement horizontal entre les cartes
      mainAxisSpacing: 10, // Espacement vertical entre les cartes
      childAspectRatio: 3 / 2, // Ratio largeur/hauteur des cartes
    ),
    itemCount: cardData.length, // Nombre d'éléments
    itemBuilder: (context, index) {
      final item = cardData[index];
      return InkWell(
        onTap: (){},
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item["title"]!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item["subtitle"]!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
}
