import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/modify_propoerty.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementProperty extends StatefulWidget {
  final String uid;
  final Future<List<Lot?>> lotByUser;
  final String refLot;
  final Color color;

  const ManagementProperty(
      {super.key,
      required this.lotByUser,
      required this.color,
      required this.uid,
      required this.refLot});
  @override
  ManagementPropertyState createState() => ManagementPropertyState();
}

class ManagementPropertyState extends State<ManagementProperty> {
  late Color _backgroundColor;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            'Gestion des biens', Colors.black87, SizeFont.h1.size),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: FutureBuilder<List<Lot?>>(
          future: widget.lotByUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Aucun bien trouvé.'));
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  Lot? lot = snapshot.data![index];
                  bool loca = lot!.idLocataire!.contains(widget.uid);
                  _backgroundColor = Color(
                      int.parse(lot.colorSelected.substring(2), radix: 16) +
                          0xFF000000);
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => ModifyProperty(
                                    refLotSelected: widget.refLot,
                                    lot: lot,
                                    uid: widget.uid,
                                  )));
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _backgroundColor,
                        radius: 10, // Rayon du cercle
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape
                                .circle, // Définir la forme comme un cercle
                          ),
                        ),
                      ),
                      title: loca
                          ? MyTextStyle.lotName(
                              (lot.nameLoc != "")
                                  ? lot.nameLoc
                                  : "${lot.residenceData['name']} ${lot.lot!}",
                              Colors.black87,
                              SizeFont.h2.size,
                            )
                          : MyTextStyle.lotName(
                              (lot.nameProp != "")
                                  ? lot.nameProp
                                  : "${lot.residenceData['name']} ${lot.lot!}",
                              Colors.black87,
                              SizeFont.h2.size,
                            ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MyTextStyle.lotDesc(
                                  lot.residenceData["numero"] ?? "N/A",
                                  SizeFont.h3.size),
                              Container(
                                  padding: const EdgeInsets.only(left: 4)),
                              MyTextStyle.lotDesc(
                                  lot.residenceData["street"] ?? "N/A",
                                  SizeFont.h3.size),
                              Container(
                                  padding: const EdgeInsets.only(left: 4)),
                            ],
                          ),
                          Row(
                            children: [
                              MyTextStyle.lotDesc(
                                  lot.residenceData["zipCode"] ?? "N/A",
                                  SizeFont.h3.size),
                              Container(
                                  padding: const EdgeInsets.only(left: 4)),
                              MyTextStyle.lotDesc(
                                  lot.residenceData["city"] ?? "N/A",
                                  SizeFont.h3.size),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_right_outlined,
                        size: 30,
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(
                  thickness: 0.7,
                ),
              );
            }
          },
        ),
      ),
      bottomSheet: Container(
        height: 50,
        //alignment: Alignment.bottomCenter,
        color: Colors.transparent,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: ButtonAdd(
              function: () {},
              text: "Rattacher un lot",
              color: Theme.of(context).primaryColor,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size),
        ),
      ),
    );
  }
}
