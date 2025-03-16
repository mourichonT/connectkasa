import 'package:connect_kasa/controllers/features/load_prefered_data.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart'
    as local_user; // Alias pour la classe User locale
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_property.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/management_tenant.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/info_pers_page_modify.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Alias pour la classe User de firebase_auth

class OldProfilPage extends StatefulWidget {
  final String uid;
  final Color color;
  final String refLot;

  const OldProfilPage({
    super.key,
    required this.uid,
    required this.color,
    required this.refLot,
  });

  @override
  _OldProfilPageState createState() => _OldProfilPageState();
}

class _OldProfilPageState extends State<OldProfilPage> {
  final LoadUserController _loadUserController = LoadUserController();
  DataBasesUserServices userServices = DataBasesUserServices();
  local_user.User? user;
  String name = "";
  String surname = "";
  String pseudo = "";
  String bio = "";
  String job = "";
  bool privateAccount = true;
  String email = "";
  final DataBasesLotServices _databasesLotServices = DataBasesLotServices();
  late Future<List<Lot?>> _lotByUser;
  int nbrLot = 0;
  int nbrLoc = 0;
  bool loca = false;

  @override
  void initState() {
    super.initState();
    _loadUser(widget.uid);
    _lotByUser = _databasesLotServices.getLotByIdUser(widget.uid);

    _lotByUser.then((lots) {
      setState(() {
        nbrLot = lots.length;
      });

      // Parcourir chaque lot pour vérifier si widget.uid est locataire
      for (Lot? lot in lots) {
        if (lot != null) {
          if (lot.idLocataire!.contains(widget.uid)) {
            loca = true;
            break; // Sortir de la boucle dès qu'un lot est trouvé où widget.uid est locataire
          } else if (lot.idProprietaire!.contains(widget.uid)) {
            loca = false;
            break; // Sortir de la boucle dès qu'un lot est trouvé où widget.uid est propriétaire
          }
        }
      }

      // Récupérer le nombre de locataires, en excluant widget.uid
      _databasesLotServices
          .countLocatairesExcludingUser(widget.uid)
          .then((tenants) {
        setState(() {
          nbrLoc = tenants;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName("Profil", Colors.black87, SizeFont.h1.size),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfilTile(widget.uid, 45, 40, 45, false),
                        ],
                      ),
                    ),
                    pseudo != ""
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: MyTextStyle.lotDesc(pseudo, SizeFont.h3.size,
                                FontStyle.normal, FontWeight.bold),
                          )
                        : Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: MyTextStyle.lotDesc(
                                    name,
                                    SizeFont.h3.size,
                                    FontStyle.normal,
                                    FontWeight.bold),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: MyTextStyle.lotDesc(
                                    surname,
                                    SizeFont.h3.size,
                                    FontStyle.normal,
                                    FontWeight.bold),
                              )
                            ],
                          ),
                    // Card(
                    //   color: Colors.white,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(16.0),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //       children: [
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Row(
                    //               mainAxisAlignment:
                    //                   MainAxisAlignment.spaceBetween,
                    //               children: [
                    //                 MyTextStyle.lotName("Votre solde",
                    //                     Colors.black87, SizeFont.h3.size),
                    //               ],
                    //             ),
                    //             SizedBox(height: 20),
                    //             Align(
                    //               alignment: Alignment.centerLeft,
                    //               child: Row(
                    //                 children: [
                    //                   MyTextStyle.lotName(user!.solde,
                    //                       Colors.black87, SizeFont.header.size),
                    //                   MyTextStyle.lotName("€", Colors.black87,
                    //                       SizeFont.header.size),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             ButtonAdd(
                    //                 color: widget.color,
                    //                 text: "Recharger",
                    //                 horizontal: 10,
                    //                 vertical: 5,
                    //                 size: SizeFont.h3.size),
                    //             SizedBox(
                    //               height: 10,
                    //             ),
                    //             ButtonAdd(
                    //                 color: Colors.teal,
                    //                 text: "Retirer",
                    //                 horizontal: 20,
                    //                 vertical: 5,
                    //                 size: SizeFont.h3.size)
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => ManagementProperty(
                                            refLot: widget.refLot,
                                            uid: widget.uid,
                                            lotByUser: _lotByUser,
                                            color: widget.color,
                                          )));
                            },
                            child: Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        MyTextStyle.lotName(nbrLot.toString(),
                                            widget.color, SizeFont.header.size),
                                        MyTextStyle.lotName("Biens",
                                            Colors.black54, SizeFont.h3.size),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !loca,
                          child: Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => ManagementTenant(
                                              uid: widget.uid,
                                              lotByUser: _lotByUser,
                                              color: widget.color,
                                            )));
                              },
                              child: Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          MyTextStyle.lotName(
                                              nbrLoc.toString(),
                                              widget.color,
                                              SizeFont.header.size),
                                          MyTextStyle.lotName("Locataires",
                                              Colors.black54, SizeFont.h3.size),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: MyTextStyle.lotName("Vos informations",
                                Colors.black87, SizeFont.h2.size)),
                        // Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MyTextStyle.lotDesc(
                              "Nom", SizeFont.para.size, FontStyle.italic),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 15, right: 15),
                          child: MyTextStyle.lotDesc(
                              name, SizeFont.h3.size, FontStyle.normal),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MyTextStyle.lotDesc(
                              "Prénom", SizeFont.para.size, FontStyle.italic),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 15, right: 15),
                          child: MyTextStyle.lotDesc(
                              surname, SizeFont.h3.size, FontStyle.normal),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MyTextStyle.lotDesc(
                              "Email", SizeFont.para.size, FontStyle.italic),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 15, right: 15),
                          child: MyTextStyle.lotDesc(
                              email, SizeFont.h3.size, FontStyle.normal),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MyTextStyle.lotDesc("Profession",
                              SizeFont.para.size, FontStyle.italic),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 15, right: 15),
                          child: MyTextStyle.lotDesc(
                              job, SizeFont.h3.size, FontStyle.normal),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MyTextStyle.lotDesc("Biographie",
                              SizeFont.para.size, FontStyle.italic),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 15, right: 15),
                          child: MyTextStyle.lotDesc(
                              bio, SizeFont.h3.size, FontStyle.normal),
                        ),
                        const Divider(),
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ButtonAdd(
                              function: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            InfoPersoPageModify(
                                              email: email,
                                              uid: widget.uid,
                                              color: widget.color,
                                              refresh: () {},
                                              user: user!,
                                              refLot: "",
                                            )));
                              },
                              color: widget.color,
                              icon: Icons.edit,
                              // text: "Modifier",
                              horizontal: 20,
                              vertical: 5,
                              size: SizeFont.h3.size),
                          const SizedBox(
                            width: 10,
                          ),
                          ButtonAdd(
                              function: () {
                                _loadUserController.handleGoogleSignOut();
                                Navigator.popUntil(
                                    context, ModalRoute.withName('/'));
                                LoadPreferedData.clearSharedPreferences();
                              },
                              color: Colors.black26,
                              //text: "Déconnexion",
                              icon: Icons.power_settings_new_rounded,
                              horizontal: 20,
                              vertical: 5,
                              size: SizeFont.h3.size)
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _loadUser(String uid) async {
    if (uid.isNotEmpty) {
      user = await userServices.getUserById(uid);
      if (user != null) {
        name = user!.name;
        surname = user!.surname;
        pseudo = user!.pseudo!;
        bio = user!.bio!;
        job = user!.profession!;
        privateAccount = user!.private; // Met à jour l'état du compte privé
      }
      // Récupérer l'adresse e-mail de l'utilisateur depuis Firebase Auth
      email = await LoadUserController.getUserEmail(uid);
      setState(() {});
    }
  }

  // Future<String> _getUserEmail(String uid) async {
  //   firebase_auth.User? firebaseUser =
  //       firebase_auth.FirebaseAuth.instance.currentUser;
  //   if (firebaseUser != null && firebaseUser.uid == uid) {
  //     return firebaseUser.email ?? "";
  //   } else {
  //     // Si l'utilisateur actuel ne correspond pas à l'uid, récupérez l'utilisateur via l'API Admin (nécessite un backend)
  //     return ""; // Gérer en fonction de votre logique
  //   }
  // }
}
