import 'dart:async';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';

class Step0 extends StatefulWidget {
  final String userId;
  final String emailUser;
  final Function(String, String, String, String) recupererInformationsStep0;
  final int currentPage;
  final PageController progressController;

  const Step0({
    super.key,
    required this.emailUser,
    required this.userId,
    required this.recupererInformationsStep0,
    required this.currentPage,
    required this.progressController,
  });

  @override
  _Step0State createState() => _Step0State();
}

class _Step0State extends State<Step0> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _pseudoController = TextEditingController();
  Timer? _deleteTimer;

  String getNom() {
    return _nameController.text;
  }

  String getPrenom() {
    return _surnameController.text;
  }

  String getPseudo() {
    return _pseudoController.text;
  }

  // Méthode pour démarrer le timer de suppression
  void _startDeletionTimer() {
    _deleteTimer = Timer(Duration(minutes: 30), () {
      DataBasesUserServices.removeUserById(widget.userId);
    });
  }

  // Observateur du cycle de vie de l'application pour détecter si l'app est en arrière-plan ou au premier plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Application fermée ou mise en arrière-plan : suppression de l'utilisateur
      _deleteUser();
    }
  }

// Supprimer l'utilisateur si l'inscription n'est pas terminée
Future<void> _deleteUser() async {
  // Créez une instance de DataBasesUserServices
  DataBasesUserServices databaseService = DataBasesUserServices();

  // Utilisez cette instance pour appeler la méthode getUserById
  User? user = await databaseService.getUserById(widget.userId);

  // Vérifiez si l'utilisateur n'existe pas
  if (user != null) {
    // Si l'utilisateur n'est pas trouvé, supprimez-le
    await DataBasesUserServices.removeUserById(widget.userId);
  } 
}


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startDeletionTimer();
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Vérifie si l'utilisateur a complété son inscription avant de le supprimer
    _deleteUser();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MyTextStyle.lotName(
                    """Vous venez de vous installer dans une résidence du réseau ConnectKasa. Commençons par renseigner quelques informations. """,
                    Colors.black54),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Row(
                  children: [
                    Container(
                      width: 150,
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        "Nom de famille * :",
                        style: GoogleFonts.robotoCondensed(
                            fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        onEditingComplete: () => setState(() {}),
                        decoration: InputDecoration(
                            hintText: 'Nom',
                            hintStyle: GoogleFonts.robotoCondensed(
                                color: Colors.black45)),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: getNom().isNotEmpty,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Row(
                        children: [
                          Container(
                            width: 150,
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              "Prénom * :",
                              style: GoogleFonts.robotoCondensed(
                                  fontSize: 16, color: Colors.black87),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _surnameController,
                              onEditingComplete: () =>
                                  setState(() {}),
                              decoration: InputDecoration(
                                  hintText: 'Prénom',
                                  hintStyle: GoogleFonts.robotoCondensed(
                                      color: Colors.black45)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Row(
                        children: [
                          Container(
                            width: 150,
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              "Pseudo :",
                              style: GoogleFonts.robotoCondensed(
                                  fontSize: 16, color: Colors.black45),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _pseudoController,
                              decoration: InputDecoration(
                                  hintText: 'Pseudo',
                                  hintStyle: GoogleFonts.robotoCondensed(
                                      color: Colors.black45)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: getPrenom().isNotEmpty,
        child: BottomAppBar(
            surfaceTintColor: Colors.white,
            padding: const EdgeInsets.all(2),
            height: 70,
            child: Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  TextButton(
                    onPressed: () {
                      String nom = getNom();
                      String prenom = getPrenom();
                      String pseudo = getPseudo();
                      widget.recupererInformationsStep0(
                          widget.emailUser, nom, prenom, pseudo);
                      if (widget.currentPage < 5) {
                        widget.progressController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: const Text(
                      'Suivant',
                    ),
                  ),
                ]))),
      ),
    );
  }
}
