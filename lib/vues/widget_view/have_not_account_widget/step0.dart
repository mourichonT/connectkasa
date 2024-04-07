import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Step0 extends StatefulWidget {
  final String newUser;
  final Function(String, String, String) recupererInformationsStep0;
  final int currentPage;
  final PageController progressController;

  const Step0({
    Key? key,
    required this.newUser,
    required this.recupererInformationsStep0,
    required this.currentPage,
    required this.progressController,
  }) : super(key: key);

  @override
  _Step0State createState() => _Step0State();
}

class _Step0State extends State<Step0> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _pseudoController = TextEditingController();

  String getNom() {
    return _nameController.text;
  }

  String getPrenom() {
    return _surnameController.text;
  }

  String getPseudo() {
    return _pseudoController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: MyTextStyle.lotName(
                    """Vous venez de vous installer dans une résidence du réseau ConnectKasa. Commençons par renseigner quelques informations. """,
                    Colors.black54),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Row(
                  children: [
                    Container(
                      width: 150,
                      padding: EdgeInsets.only(right: 20),
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
                          EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Row(
                        children: [
                          Container(
                            width: 150,
                            padding: EdgeInsets.only(right: 20),
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
                                  setState(() {}), // Ajoutez cette ligne
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
                          EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Row(
                        children: [
                          Container(
                            width: 150,
                            padding: EdgeInsets.only(right: 20),
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
            padding: EdgeInsets.all(2),
            height: 70,
            child: Container(
                // decoration: BoxDecoration(color: Colors.amber),
                //height: 30,
                //padding: EdgeInsets.only(bottom: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  TextButton(
                    onPressed: () {
                      String nom = getNom();
                      String prenom = getPrenom();
                      String pseudo = getPseudo();
                      widget.recupererInformationsStep0(nom, prenom, pseudo);
                      // Action à effectuer lorsque le bouton "Suivant" est pressé
                      if (widget.currentPage < 5) {
                        widget.progressController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      'Suivant',
                    ),
                  ),
                ]))),
      ),
    );
  }
}
