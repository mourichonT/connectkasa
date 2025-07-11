import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/pages_vues/residence_page/management_res_info_g.dart';
import 'package:connect_kasa/vues/pages_vues/residence_page/manage_contact.dart';
import 'package:connect_kasa/vues/pages_vues/residence_page/manage_cs_members.dart';
import 'package:connect_kasa/vues/pages_vues/residence_page/manage_list_lot.dart';
import 'package:connect_kasa/vues/pages_vues/residence_page/manage_structure.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_page_menu.dart';

class ResidencePage extends StatefulWidget {
  final String uid;
  final Color color;
  final Residence residence;

  const ResidencePage({
    super.key,
    required this.uid,
    required this.color,
    required this.residence,
  });

  @override
  State<StatefulWidget> createState() => _ResidencePageState();
}

class _ResidencePageState extends State<ResidencePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: MyTextStyle.lotName(
          "Gestion de votre résidence",
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  text: "Informations générales",
                  icon: const Icon(Icons.info_outline, size: 22),
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManagementResInfoG(
                            color: widget.color, residence: widget.residence),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  text: "Configuration de la résidence",
                  icon: const Icon(Icons.apartment, size: 22),
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageStructure(
                            color: widget.color, residence: widget.residence),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  text: "Gestion des contacts",
                  icon: const Icon(Icons.contact_phone_outlined, size: 22),
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageContact(
                            color: widget.color, residence: widget.residence),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  text: "Gestion des lots",
                  icon: const Icon(Icons.home_work_outlined, size: 22),
                  press: () {
                    // Naviguer vers la gestion des lots
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageListLot(
                            color: widget.color, residence: widget.residence),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  text: "Gestion des membres du CS",
                  icon: const Icon(Icons.group_outlined, size: 22),
                  press: () {
                    // Naviguer vers la gestion du conseil syndical
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageCsMembers(
                            color: widget.color, residence: widget.residence),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
