import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_garants.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/my_infos_rent.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_pers_page_modify.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/account_secu_modify.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagementFolderRent extends StatefulWidget {
  final String uid;
  final Color color;

  const ManagementFolderRent({
    super.key,
    required this.uid,
    required this.color,
  });

  @override
  _ManagementFolderRentState createState() => _ManagementFolderRentState();
}

class _ManagementFolderRentState extends State<ManagementFolderRent> {
  final LoadUserController _loadUserController = LoadUserController();
  final DataBasesUserServices userServices = DataBasesUserServices();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();

  String? docId = "";

  @override
  void initState() {
    super.initState();
    _loadDocId(); // Lance la fonction async sans "await"
  }

  void _loadDocId() async {
    final id = await DataBasesUserServices.getFirstDocId(widget.uid);
    if (mounted) {
      setState(() {
        docId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: MyTextStyle.lotName(
            "Mon dossier locataire", Colors.black87, SizeFont.h1.size),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: "",
                  text: "Mes informations locataire",
                  icon: const Icon(Icons.info_outlined, size: 22),
                  press: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyInfosRent(
                          uid: widget.uid,
                          color: widget.color,
                          docId: docId,
                        ),
                      ),
                    );
                  }, // Utilisation de la fonction pour naviguer et récupérer les données mises à jour
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: "",
                  text: "Mes garants",
                  icon: const Icon(Icons.gpp_good_outlined, size: 22),
                  press: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManagementGarants(
                                docId: docId!,
                                color: widget.color,
                                uid: widget.uid,
                              )),
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
