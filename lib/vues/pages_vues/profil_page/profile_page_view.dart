import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_property.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_tenant.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_profil_pic.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/param_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_pers_page_modify.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final Color color;
  final String refLot;

  const ProfilePage({
    super.key,
    required this.uid,
    required this.color,
    required this.refLot,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LoadUserController _loadUserController = LoadUserController();
  final DataBasesUserServices userServices = DataBasesUserServices();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();

  User? user;
  Future<List<Lot?>>? _lotByUser;
  int nbrLot = 0;
  int nbrLoc = 0;
  bool loca = false;
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
    _loadLotsData();
  }

  void _loadLotsData() {
    _lotByUser = _databasesLotServices.getLotByIdUser(widget.uid);
    _lotByUser!.then((lots) {
      setState(() {
        nbrLot = lots.length;
      });

      for (Lot? lot in lots) {
        if (lot != null) {
          if (lot.idLocataire!.contains(widget.uid)) {
            setState(() {
              loca = true;
            });
            break;
          } else if (lot.idProprietaire!.contains(widget.uid)) {
            setState(() {
              loca = false;
            });
            break;
          }
        }
      }
    });

    _databasesLotServices
        .countLocatairesExcludingUser(widget.uid)
        .then((tenants) {
      setState(() {
        nbrLoc = tenants;
      });
    });
  }

  Future<void> _loadUser(String uid) async {
    if (uid.isNotEmpty) {
      User? fetchedUser = await userServices.getUserById(uid);
      if (fetchedUser != null) {
        setState(() {
          user = fetchedUser;
          name = fetchedUser.name;
          surname = fetchedUser.surname;
          pseudo = fetchedUser.pseudo ?? "";
          bio = fetchedUser.bio ?? "";
          job = fetchedUser.profession ?? "";
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
        title:
            MyTextStyle.lotName("Mon profil", Colors.black87, SizeFont.h1.size),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, '/MyNavBar',
                  arguments: widget.uid // Passer l'uid ici
                  );
              // Navigator.pop(context); // Ferme le drawer
              // Renvoie l'utilisateur avec les nouvelles données
            }),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                ProfilePic(
                  imagePath: profilPic,
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                  refresh: _initializeUserData,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyTextStyle.lotDesc(
                            name,
                            SizeFont.h3.size,
                            FontStyle.normal,
                            FontWeight.bold,
                          ),
                          const SizedBox(width: 5),
                          MyTextStyle.lotDesc(
                            surname,
                            SizeFont.h3.size,
                            FontStyle.normal,
                            FontWeight.bold,
                          ),
                        ],
                      ),
                      Visibility(
                        visible: pseudo.isNotEmpty,
                        child: MyTextStyle.lotDesc(
                          "@$pseudo",
                          SizeFont.h3.size,
                          FontStyle.italic,
                          FontWeight.normal,
                        ),
                      ),
                      Visibility(
                        visible: job.isNotEmpty,
                        child: MyTextStyle.lotDesc(
                          "$job",
                          SizeFont.h3.size,
                          FontStyle.italic,
                          FontWeight.normal,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            !privateAccount
                                ? Icon(
                                    Icons.public,
                                    size: SizeFont.h3.size,
                                    color: Colors.black54,
                                  )
                                : Icon(
                                    Icons.lock_outlined,
                                    size: SizeFont.h3.size,
                                    color: Colors.black54,
                                  ),
                            SizedBox(
                              width: 10,
                            ),
                            MyTextStyle.lotDesc(
                              !privateAccount
                                  ? "Ce compte est public"
                                  : "Ce compte est privé",
                              SizeFont.h3.size,
                              FontStyle.normal,
                              FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 15, bottom: 30),
                  child: MyTextStyle.lotDesc(
                    "$bio",
                    SizeFont.h3.size,
                    FontStyle.normal,
                    FontWeight.normal,
                  ),
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                  text: "Mes informations",
                  icon: const Icon(Icons.person_2_rounded, size: 22),
                  press: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => InfoPageView(
                                  refLot: widget.refLot,
                                  uid: widget.uid,
                                  color: widget.color,
                                )));
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                  text: "Ma gestion immobilière",
                  icon: const Icon(Icons.home_work_outlined, size: 22),
                  press: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => ManagementProperty(
                                  refLot: widget.refLot,
                                  uid: widget.uid,
                                  lotByUser: _lotByUser!,
                                  color: widget.color,
                                )));
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                  text: "Mes locataires",
                  icon: const Icon(Icons.group_outlined, size: 22),
                  press: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => ManagementTenant(
                                  uid: widget.uid,
                                  lotByUser: _lotByUser!,
                                  color: widget.color,
                                )));
                  },
                  isLogOut: false,
                ),
                ProfileMenu(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                  text: "Paramètres",
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  press: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => ParamPage(
                                  refLot: widget.refLot,
                                  uid: widget.uid,
                                  color: widget.color,
                                )));
                  },
                  isLogOut: false,
                ),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ProfileMenu(
                uid: widget.uid,
                color: widget.color,
                refLot: widget.refLot,
                text: "Déconnexion",
                icon: const Icon(Icons.power_settings_new_rounded,
                    color: Colors.white, size: 22),
                press: () {
                  _loadUserController.handleGoogleSignOut();
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                  LoadPreferedData.clearSharedPreferences();
                },
                isLogOut: true,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
