import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/new_profile_page_view.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class ProfilPageModify extends StatefulWidget {
  final User user;
  final String uid;
  final Color color;
  final String email;
  final Function refresh;
  final String refLot;

  const ProfilPageModify({
    super.key,
    required this.uid,
    required this.color,
    required this.email,
    required this.refresh,
    required this.user,
    required this.refLot,
  });

  @override
  _ProfilPageModifyState createState() => _ProfilPageModifyState();
}

class _ProfilPageModifyState extends State<ProfilPageModify> {
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController pseudo = TextEditingController();
  TextEditingController bio = TextEditingController();
  TextEditingController profession = TextEditingController();
  DataBasesUserServices userServices = DataBasesUserServices();
  String? profilPic = "";

  FocusNode nameFocusNode = FocusNode();
  FocusNode surnameFocusNode = FocusNode();
  FocusNode pseudoFocusNode = FocusNode();
  FocusNode bioFocusNode = FocusNode();

  bool privateAccount = true;

  @override
  void initState() {
    super.initState();

    // Initialisation avec les valeurs de widget.user
    name.text = widget.user.name;
    surname.text = widget.user.surname;
    pseudo.text = widget.user.pseudo!;
    bio.text = widget.user.bio!;
    profilPic = widget.user.profilPic;
    privateAccount = widget.user.private; // Met à jour l'état du compte privé

    nameFocusNode.addListener(() => setState(() {}));
    surnameFocusNode.addListener(() => setState(() {}));
    pseudoFocusNode.addListener(() => setState(() {}));
    bioFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    surnameFocusNode.dispose();
    pseudoFocusNode.dispose();
    bioFocusNode.dispose();

    name.dispose();
    surname.dispose();
    pseudo.dispose();
    bio.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Modifier vos informations", Colors.black87, SizeFont.h1.size),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Lorsque l'utilisateur appuie sur la flèche de retour,
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewProfilePage(
                  uid: widget.uid,
                  color: widget.color,
                  refLot: widget.refLot,
                ),
              ),
            ); // Renvoie l'utilisateur avec les nouvelles données
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildReadOnlyTextField('Email', widget.email),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ButtonAdd(
                    function: () {
                      resetPassword(widget.email);
                    },
                    colorText: widget.color,
                    borderColor: widget.color,
                    color: Colors.transparent,
                    text: 'Réinitialiser le mot de passe',
                    horizontal: 10,
                    vertical: 10,
                    size: SizeFont.h3.size),
              ),
              _buildModifyTextField("name", 'Nom', name, nameFocusNode),
              _buildModifyTextField(
                  "surname", 'Prénom', surname, surnameFocusNode),
              _buildModifyTextField(
                  "pseudo", "Pseudo", pseudo, pseudoFocusNode),
              _buildModifyTextField("bio", "Biographie", bio, bioFocusNode,
                  maxLines: 5, minLines: 2),
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyTextStyle.lotDesc(
                        "Compte privé", SizeFont.h3.size, FontStyle.normal),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: privateAccount,
                        onChanged: (bool value) {
                          setState(() {
                            privateAccount = value;
                            // Met à jour l'état du compte privé
                            widget.user.private = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModifyTextField(String field, String label,
      TextEditingController controller, FocusNode focusNode,
      {int maxLines = 5, int minLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: maxLines,
              minLines: minLines,
              onSubmitted: (value) {},
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: SizeFont.h3.size,
              ),
            ),
          ),
          if (focusNode.hasFocus)
            IconButton(
              onPressed: () async {
                try {
                  await DataBasesUserServices.updateUserField(
                      widget.uid, field, controller.text);
                  widget.refresh;
                  // Perdre le focus après la validation
                  focusNode.unfocus();
                  // Affiche un message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label mis à jour avec succès!'),
                    ),
                  );
                } catch (e) {
                  // En cas d'erreur, afficher un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Erreur lors de la mise à jour du champ $label: $e'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: TextEditingController(text: value ?? ''),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
          enabled: false,
          border: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
        ),
        style: TextStyle(
          color: Colors.black54,
          fontSize: SizeFont.h3.size,
        ),
      ),
    );
  }

  Future<void> resetPassword(String email) async {
    try {
      await firebase_auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);
      // Affichez un message à l'utilisateur indiquant que l'e-mail de réinitialisation a été envoyé
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Réinitialisation du mot de passe'),
            content: Text(
                'Un e-mail de réinitialisation du mot de passe a été envoyé à $email.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Gérez les erreurs ici, par exemple, si l'e-mail n'est pas valide ou si une autre erreur survient
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur'),
            content: const Text(
                'Erreur lors de l\'envoi de l\'e-mail de réinitialisation du mot de passe.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
