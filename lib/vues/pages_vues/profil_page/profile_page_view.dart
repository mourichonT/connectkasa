import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_property.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/residence_page.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_tenant.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_page_menu.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_profil_pic.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/param_page_view.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_pers_page_modify.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final Color color;
  final String refLot;
  final List<Lot>? lots;

  const ProfilePage({
    super.key,
    required this.uid,
    required this.color,
    required this.refLot,
    this.lots,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LoadUserController _loadUserController = LoadUserController();
  final DataBasesUserServices userServices = DataBasesUserServices();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();
  final DataBasesResidenceServices _basesResidenceServices =
      DataBasesResidenceServices();

  User? user;

  int nbrLot = 0;
  int nbrCS = 0;
  bool loca = false;
  String name = "";
  String surname = "";
  String pseudo = "";
  String bio = "";
  String job = "";
  String profilPic = "";
  bool privateAccount = true;
  String email = "";
  bool isOwner = false;
  bool isMemberCS = false;
  List<Residence> residenceObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    _loadUser(widget.uid);
  }

  void _checkOwnership() {
    if (widget.lots != null) {
      setState(() {
        isOwner =
            widget.lots!.any((lot) => lot.idProprietaire!.contains(widget.uid));
      });
    }
  }

  void _checkCSMember() async {
    if (widget.lots != null) {
      final csResidences = widget.lots!
          .where((lot) =>
              lot.residenceData["csmembers"] != null &&
              List<String>.from(lot.residenceData["csmembers"])
                  .contains(widget.uid))
          .toList();

      // Liste des ID des résidences
      final List<String> csResidenceIds =
          csResidences.map((lot) => lot.residenceId).toList();

      // Récupération des objets Residence correspondants
      List<Residence> csResidenceObjects = [];

      for (String residenceId in csResidenceIds) {
        Residence? res =
            await _basesResidenceServices.getResidenceByRef(residenceId);
        if (res != null) {
          csResidenceObjects.add(res);
        }
      }

      print("Résidences CS trouvées : ${csResidenceObjects.length}");

      setState(() {
        isMemberCS = csResidenceObjects.isNotEmpty;
        nbrCS = csResidenceObjects.length;
        residenceObjects = csResidenceObjects; // <-- à déclarer
      });
    }
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
        _checkOwnership();
        _checkCSMember();
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
            Navigator.pushNamed(context, '/MyNavBar', arguments: widget.uid);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        privateAccount
                                            ? Icons.lock_outlined
                                            : Icons.public,
                                        size: SizeFont.h3.size,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 10),
                                      MyTextStyle.lotDesc(
                                        privateAccount
                                            ? "Ce compte est privé"
                                            : "Ce compte est public",
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
                            padding: const EdgeInsets.only(
                                left: 20, right: 15, bottom: 30),
                            child: MyTextStyle.lotDesc(
                              bio,
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
                                    lots: widget.lots,
                                    refLot: widget.refLot,
                                    uid: widget.uid,
                                    color: widget.color,
                                  ),
                                ),
                              ).then((_) {
                                // Cette fonction sera appelée au retour
                                _initializeUserData(); // Remets à jour les données
                              });
                            },
                            isLogOut: false,
                          ),
                          ProfileMenu(
                            uid: widget.uid,
                            color: widget.color,
                            refLot: widget.refLot,
                            text: "Ma gestion immobilière",
                            icon:
                                const Icon(Icons.home_work_outlined, size: 22),
                            press: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => ManagementProperty(
                                    refLot: widget.refLot,
                                    uid: widget.uid,
                                    color: widget.color,
                                  ),
                                ),
                              );
                            },
                            isLogOut: false,
                          ),
                          Visibility(
                            visible: isOwner,
                            child: ProfileMenu(
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
                                      color: widget.color,
                                    ),
                                  ),
                                );
                              },
                              isLogOut: false,
                            ),
                          ),
                          Visibility(
                            visible: isMemberCS,
                            child: ProfileMenu(
                              uid: widget.uid,
                              color: widget.color,
                              refLot: widget.refLot,
                              text:
                                  nbrCS > 1 ? "Mes résidences" : "Ma résidence",
                              icon:
                                  const Icon(Icons.business_outlined, size: 22),
                              press: () {
                                if (residenceObjects.length <= 1) {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ResidencePage(
                                        uid: widget.uid,
                                        color: widget.color,
                                        residence: residenceObjects[0],
                                      ),
                                    ),
                                  );
                                } else {
                                  print("residenceIds.length > 1 ");
                                }
                              },
                              isLogOut: false,
                            ),
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
                                  ),
                                ),
                              ).then((_) {
                                // Cette fonction sera appelée au retour
                                _initializeUserData(); // Remets à jour les données
                              });
                            },
                            isLogOut: false,
                          ),
                        ],
                      ),
                    ),

                    // BOUTON DE DÉCONNEXION EN BAS FIXÉ
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
                          LoadPreferedData.clearSharedPreferences();
                          _loadUserController.handleGoogleSignOut();
                          Navigator.popUntil(context, ModalRoute.withName('/'));
                          Provider.of<ColorProvider>(context, listen: false)
                              .updateColor("ff48775b");
                        },
                        isLogOut: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
