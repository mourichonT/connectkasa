import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/components/button_add.dart';
import 'package:connect_kasa/vues/pages_vues/modify_propoerty.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementProperty extends StatefulWidget {
  final String uid;
  final Future<List<Lot?>> lotByUser;
  final Color color;

  const ManagementProperty(
      {super.key,
      required this.lotByUser,
      required this.color,
      required this.uid,
      d});
  @override
  ManagementPropertyState createState() => ManagementPropertyState();
}

class ManagementPropertyState extends State<ManagementProperty> {
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
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Aucun bien trouvé.'));
            } else {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  Lot? lot = snapshot.data![index];
                  bool loca = lot!.idLocataire!.contains(widget.uid);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => ModifyProperty(
                                    lot: lot!,
                                    uid: widget.uid,
                                  )));
                    },
                    child: ListTile(
                      title: loca
                          ? MyTextStyle.lotName(
                              (lot.nameLoc != null && lot?.nameLoc != "")
                                  ? lot!.nameLoc
                                  : "${lot!.residenceData['name']} ${lot.lot!}",
                              Colors.black87,
                              SizeFont.h2.size,
                            )
                          : MyTextStyle.lotName(
                              (lot?.nameProp != null && lot?.nameProp != "")
                                  ? lot!.nameProp
                                  : "${lot!.residenceData['name']} ${lot.lot!}",
                              Colors.black87,
                              SizeFont.h2.size,
                            ),
                      trailing: Icon(
                        Icons.arrow_right_outlined,
                        size: 30,
                      ),
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) => Divider(
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
              color: widget.color,
              horizontal: 30,
              vertical: 10,
              size: SizeFont.h3.size),
        ),
      ),
    );
  }
}
