import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/manage_app/management_garants.dart';
import 'package:konodal/vues/pages_vues/manage_app/my_infos_rent.dart';
import 'package:konodal/vues/pages_vues/manage_app/my_pending_demands.dart';
import 'package:konodal/vues/pages_vues/manage_app/my_situation_personnelle.dart';
import 'package:konodal/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/share_rent_folder.dart';
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
  State<ManagementFolderRent> createState() => _ManagementFolderRentState();
}

class _ManagementFolderRentState extends State<ManagementFolderRent> {
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
                  idLot: "",
                  text: "Mes informations locataire",
                  icon: const Icon(Icons.info_outlined, size: 22),
                  press: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyInfosRent(
                          uid: widget.uid,
                          color: widget.color,
                        ),
                      ),
                    );
                  }, // Utilisation de la fonction pour naviguer et récupérer les données mises à jour
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  idLot: "",
                  text: "Ma situation personnelle",
                  icon: const Icon(Icons.family_restroom_outlined, size: 22),
                  press: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MySituationPersonnelle(
                          uid: widget.uid,
                          color: widget.color,
                        ),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  idLot: "",
                  text: "Mes garants",
                  icon: const Icon(Icons.gpp_good_outlined, size: 22),
                  press: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManagementGarants(
                                color: widget.color,
                                uid: widget.uid,
                              )),
                    );
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  idLot: "",
                  text: "Mes demandes en cours",
                  icon: const Icon(Icons.send_outlined, size: 22),
                  press: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyPendingDemands(
                          uid: widget.uid,
                          color: widget.color,
                        ),
                      ),
                    );
                  },
                  isLogOut: false,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: ButtonAdd(
                  color: Colors.transparent,
                  text: "Soummettre mon dossier locataire",
                  size: SizeFont.h3.size,
                  horizontal: 20,
                  vertical: 10,
                  colorText: widget.color,
                  borderColor: widget.color,
                  function: () => ShareRentFolder.showGuarantorSelectionDialog(
                      context, widget.uid),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
