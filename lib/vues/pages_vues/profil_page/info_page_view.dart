import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_folder_rent.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/my_infos_rent.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_pers_page_modify.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/account_secu_modify.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoPageView extends StatefulWidget {
  final String uid;
  final Color color;
  final String refLot;
  final List<Lot>? lots;

  const InfoPageView({
    super.key,
    required this.uid,
    required this.color,
    required this.refLot,
    this.lots,
  });

  @override
  _InfoPageViewState createState() => _InfoPageViewState();
}

class _InfoPageViewState extends State<InfoPageView> {
  final LoadUserController _loadUserController = LoadUserController();
  final DataBasesUserServices userServices = DataBasesUserServices();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();

  User? user;
  Future<List<Lot?>>? _lotByUser;
  List<Lot>? _lotsList;
  int nbrLot = 0;
  int nbrLoc = 0;
  //bool loca = false;
  String name = "";
  String surname = "";
  String pseudo = "";
  String bio = "";
  String job = "";
  String profilPic = "";
  bool privateAccount = true;
  String email = "";

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    _loadUser(widget.uid);
  }

  Future<void> _loadUser(String uid) async {
    if (uid.isNotEmpty) {
      User? fetchedUser = await DataBasesUserServices.getUserById(uid);
      if (fetchedUser != null) {
        setState(() {
          user = fetchedUser;
          name = fetchedUser.name;
          surname = fetchedUser.surname;
          pseudo = fetchedUser.pseudo ?? "";
          bio = fetchedUser.bio ?? "";
          privateAccount = fetchedUser.private;
          profilPic = fetchedUser.profilPic ?? "";
        });
      }
      email = await LoadUserController.getUserEmail(uid);
    }
  }

  void _navigateToModifyPage() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoPersoPageModify(
          email: email,
          uid: widget.uid,
          color: widget.color,
          refresh: _initializeUserData, // Passer la fonction de mise à jour
          user: user!,
          refLot: widget.refLot,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: MyTextStyle.lotName(
            "Mes informations", Colors.black87, SizeFont.h1.size),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                  text: "Mes informations personnelles",
                  icon: const Icon(Icons.person_2_rounded, size: 22),
                  press:
                      _navigateToModifyPage, // Utilisation de la fonction pour naviguer et récupérer les données mises à jour
                  isLogOut: false,
                ),
                Visibility(
                  visible: true,
                  child: ProfileMenu(
                    uid: widget.uid,
                    color: widget.color,
                    refLot: widget.refLot,
                    text: "Mon dossier locataire",
                    icon: const Icon(Icons.euro, size: 22),
                    press: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManagementFolderRent(
                            uid: widget.uid,
                            color: widget.color,
                          ),
                        ),
                      );
                    },
                    isLogOut: false,
                  ),
                ),
                // ProfileMenu(
                //   uid: widget.uid,
                //   color: widget.color,
                //   refLot: widget.refLot,
                //   text: "Mes documents personnels",
                //   icon: const Icon(Icons.folder_outlined, size: 22),
                //   press: () {},
                //   isLogOut: false,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
