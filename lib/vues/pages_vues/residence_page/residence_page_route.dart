import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/residence_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ResidencePageRoute extends StatelessWidget {
  final String uid;
  final Color color;
  final List<Residence> residences;

  const ResidencePageRoute(
      {super.key,
      required this.uid,
      required this.color,
      required this.residences});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: MyTextStyle.lotName(
              'Gestion des biens', Colors.black87, SizeFont.h1.size),
        ),
        body: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                Residence res = residences[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ResidencePage(
                          uid: uid,
                          color: color,
                          residence: res,
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(Icons.business_outlined, size: 22),
                    title: MyTextStyle.lotName(
                        res.name, Colors.black87, SizeFont.h2.size),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyTextStyle.lotDesc(
                            "${res.numero} ${res.voie} ${res.street}",
                            SizeFont.h3.size),
                        MyTextStyle.lotDesc(
                            "${res.zipCode} ${res.city}", SizeFont.h3.size),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF757575),
                      size: 22,
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(
                thickness: 0.7,
              ),
              itemCount: residences.length,
            )));
  }
}
