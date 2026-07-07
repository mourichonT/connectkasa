import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/providers/color_provider.dart';
import 'package:connect_kasa/controllers/providers/message_provider.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/core/repositories/residence_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_residence_repository.dart';
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
import 'package:connect_kasa/vues/pages_vues/residence_page/residence_page_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final Color color;
  final String idLot;
  final List<Lot>? lots;

  const ProfilePage({
    super.key,
    required this.uid,
    required this.color,
    required this.idLot,
    this.lots,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LoadUserController _loadUserController = LoadUserController();
  final DataBasesUserServices userServices = DataBasesUserServices();
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();
  final IResidenceRepository _basesResidenceServices =
      FirestoreResidenceRepository();

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

  bool _isLoading = true; // ✅ loading global

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    await _loadUser(widget.uid);
    setState(() {
      _isLoading =
          false; // ✅ on affiche le contenu seulement quand tout est prêt
    });
  }

  void _checkOwnership() {
    if (widget.lots != null) {
      isOwner =
          widget.lots!.any((lot) => lot.idProprietaire!.contains(widget.uid));
    }
  }

  Future<void> _checkCSMember() async {
    if (widget.lots != null) {
      final csResidences = widget.lots!
          .where((lot) =>
              lot.residenceData["csmembers"] != null &&
              List<String>.from(lot.residenceData["csmembers"])
                  .contains(widget.uid))
          .toList();

      // .toSet() : dédoublonne les residenceId. Sans ça, un utilisateur
      // ayant plusieurs lots dans la même résidence (où il est membre du
      // CS) se retrouvait avec cette résidence en double dans la liste,
      // le filtre csmembers étant identique sur chacun de ses lots
      // (residenceData dénormalisé depuis la même résidence).
      final List<String> csResidenceIds =
          csResidences.map((lot) => lot.residenceId).toSet().toList();

      List<Residence> csResidenceObjects = [];
      for (String residenceId in csResidenceIds) {
        Residence? res = await _basesResidenceServices
            .getResidenceByRef(residenceId)
            .then((result) => result.when(
                success: (v) => v, failure: (error) => throw error));
        if (res != null) {
          csResidenceObjects.add(res);
        }
      }

      isMemberCS = csResidenceObjects.isNotEmpty;
      nbrCS = csResidenceObjects.length;
      residenceObjects = csResidenceObjects;
    }
  }

  Future<void> _loadUser(String uid) async {
    if (uid.isNotEmpty) {
      User? fetchedUser = await DataBasesUserServices.getUserById(uid);
      if (fetchedUser != null) {
        user = fetchedUser;
        name = fetchedUser.name;
        surname = fetchedUser.surname;
        pseudo = fetchedUser.pseudo ?? "";
        bio = fetchedUser.bio ?? "";
        privateAccount = fetchedUser.private;
        profilPic = fetchedUser.profilPic ?? "";
        _checkOwnership();
        await _checkCSMember();
      }
      email = await LoadUserController.getUserEmail(uid);
    }
  }

  void _navigateToModifyPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoPersoPageModify(
          email: email,
          uid: widget.uid,
          color: widget.color,
          refresh: _initializeUserData,
          user: user!,
          idLot: widget.idLot,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Loader global
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
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
                                  idLot: widget.idLot,
                                  refresh: _initializeUserData,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                      left: 20, right: 15, bottom: 20),
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
                                  idLot: widget.idLot,
                                  text: "Mes informations",
                                  icon: const Icon(Icons.person_2_rounded,
                                      size: 22),
                                  press: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => InfoPageView(
                                          lots: widget.lots,
                                          idLot: widget.idLot,
                                          uid: widget.uid,
                                          color: widget.color,
                                        ),
                                      ),
                                    ).then((_) => _initializeUserData());
                                  },
                                  isLogOut: false,
                                ),
                                ProfileMenu(
                                  uid: widget.uid,
                                  color: widget.color,
                                  idLot: widget.idLot,
                                  text: "Ma gestion immobilière",
                                  icon: const Icon(Icons.home_work_outlined,
                                      size: 22),
                                  press: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            ManagementProperty(
                                          idLot: widget.idLot,
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
                                    idLot: widget.idLot,
                                    text: "Mes locataires",
                                    icon: const Icon(Icons.group_outlined,
                                        size: 22),
                                    press: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              ManagementTenant(
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
                                    idLot: widget.idLot,
                                    text: nbrCS > 1
                                        ? "Mes résidences"
                                        : "Ma résidence",
                                    icon: const Icon(Icons.business_outlined,
                                        size: 22),
                                    press: () {
                                      if (residenceObjects.length == 1) {
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
                                      } else if (residenceObjects.length > 1) {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (context) =>
                                                ResidencePageRoute(
                                              uid: widget.uid,
                                              color: widget.color,
                                              residences: residenceObjects,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    isLogOut: false,
                                  ),
                                ),
                                ProfileMenu(
                                  uid: widget.uid,
                                  color: widget.color,
                                  idLot: widget.idLot,
                                  text: "Paramètres",
                                  icon: const Icon(Icons.settings_outlined,
                                      size: 22),
                                  press: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => ParamPage(
                                          idLot: widget.idLot,
                                          uid: widget.uid,
                                          color: widget.color,
                                        ),
                                      ),
                                    ).then((_) => _initializeUserData());
                                  },
                                  isLogOut: false,
                                ),
                              ],
                            ),
                          ),

                          /// BOUTON DE DÉCONNEXION EN BAS
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: ProfileMenu(
                                uid: widget.uid,
                                color: widget.color,
                                idLot: widget.idLot,
                                text: "Déconnexion",
                                icon: const Icon(Icons.power_settings_new_rounded,
                                    color: Colors.white, size: 22),
                                press: () async {
                                  // Annulé avant le sign-out : ce provider
                                  // global écouterait sinon indéfiniment les
                                  // chats de l'utilisateur précédent
                                  // (permission-denied en boucle une fois
                                  // déconnecté). Même correctif que
                                  // my_drawer.dart.
                                  context.read<MessageProvider>().reset();
                                  LoadPreferedData.clearSharedPreferences();
                                  // Attendu avant de naviguer : sans ce await,
                                  // la navigation se faisait en parallèle du
                                  // sign-out (résultat imprévisible).
                                  await _loadUserController.handleGoogleSignOut();
                                  if (!context.mounted) return;
                                  Navigator.popUntil(
                                      context, ModalRoute.withName('/'));
                                  Provider.of<ColorProvider>(context,
                                          listen: false)
                                      .updateColor("ff48775b");
                                },
                                isLogOut: true,
                              ),
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
