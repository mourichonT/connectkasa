import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/look_up_user.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ManageCsMembers extends StatefulWidget {
  final Color color;
  final Residence residence;

  const ManageCsMembers(
      {super.key, required this.color, required this.residence});
  @override
  State<StatefulWidget> createState() => ManageCsMembresState();
}

class ManageCsMembresState extends State<ManageCsMembers> {
  late List<String> _csMembers = [];

  @override
  void initState() {
    super.initState();
    _csMembers = widget.residence.csmembers ?? [];
  }

  Future<void> removeMember(int index) async {
    String uidToRemove = _csMembers[index];

    setState(() {
      _csMembers.removeAt(index);
    });

    await DataBasesResidenceServices()
        .removeCsMember(widget.residence.id, uidToRemove);
  }

  Future<void> addMember(int index) async {
    String uidToAdd = _csMembers[index];

    setState(() {
      _csMembers.add(uidToAdd);
    });

    await DataBasesResidenceServices()
        .addCsMember(widget.residence.id, uidToAdd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
          "Gestion des Membres du CS",
          Colors.black87,
          SizeFont.h1.size,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyTextStyle.postDesc(
              """Composez votre Conseil syndical, ajoutez ou retirez les membres.
Les personnes que vous ajoutez auront les droits de modifications et de suppression sur les parutions de votre résidence.""",
              SizeFont.h2.size,
              Colors.black54,
              fontweight: FontWeight.normal,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _csMembers.isEmpty
                  ? Center(
                      child: Text(
                        "Aucun membre du conseil syndical pour le moment.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.separated(
                      itemBuilder: (BuildContext context, int index) {
                        String member = _csMembers[index];
                        return ListTile(
                          trailing: IconButton(
                            onPressed: () => removeMember(index),
                            icon: const Icon(Icons.delete),
                          ),
                          title: ProfilTile(
                            member,
                            22,
                            19,
                            22,
                            true,
                            Colors.black87,
                            SizeFont.h2.size,
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(thickness: 0.7),
                      itemCount: _csMembers.length,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 95, vertical: 20),
        child: ButtonAdd(
          icon: Icons.add,
          text: 'Ajouter un membre',
          color: widget.color,
          horizontal: 20,
          vertical: 10,
          size: SizeFont.h3.size,
          function: () {
            LookUpUser.searchNewCSMembreForm(
              context,
              widget.residence.id,
              (newUser) {
                setState(() {
                  _csMembers.add(newUser.uid);
                });
              },
            );
          },
        ),
      ),
    );
  }
}
