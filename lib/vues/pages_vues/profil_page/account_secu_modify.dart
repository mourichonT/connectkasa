import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_user.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/legal_texts/info_centre.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class AccountSecuPageModify extends StatefulWidget {
  final User user;
  final String uid;
  final Color color;
  final String email;
  final Function refresh;
  final String refLot;

  const AccountSecuPageModify({
    super.key,
    required this.uid,
    required this.color,
    required this.email,
    required this.refresh,
    required this.user,
    required this.refLot,
  });

  @override
  _AccountSecuPageModifyState createState() => _AccountSecuPageModifyState();
}

class _AccountSecuPageModifyState extends State<AccountSecuPageModify> {
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
  FocusNode professionFocusNode = FocusNode();

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
    profession.text = widget.user.profession!;
    privateAccount = widget.user.private; // Met à jour l'état du compte privé

    nameFocusNode.addListener(() => setState(() {}));
    surnameFocusNode.addListener(() => setState(() {}));
    pseudoFocusNode.addListener(() => setState(() {}));
    bioFocusNode.addListener(() => setState(() {}));
    professionFocusNode.addListener(() => setState(() {}));
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
            "Compte & sécurité", Colors.black87, SizeFont.h1.size),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: MyTextStyle.lotName(
                    "Confidentialité", Colors.black87, SizeFont.h1.size),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 10, bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyTextStyle.lotDesc(
                            "Compte privé", SizeFont.h3.size, FontStyle.normal),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: privateAccount,
                            onChanged: (bool value) async {
                              setState(() {
                                privateAccount = value;
                                widget.user.private = value;
                              });
                              SubmitUser.UpdateUser(
                                  context: context,
                                  uid: widget.uid,
                                  field: 'private',
                                  label: "Confidentialité du compte",
                                  newBool: privateAccount);
                              widget.refresh();
                            },
                          ),
                        ),
                      ],
                    ),
                    MyTextStyle.lotDesc(
                      InfoCentre.privateAccount,
                      SizeFont.para.size,
                      FontStyle.italic,
                      FontWeight.normal,
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
              onPressed: () {
                SubmitUser.UpdateUser(
                  context: context,
                  uid: widget.uid,
                  field: field,
                  label: label,
                  value: controller.text,
                );
                focusNode.unfocus();
                widget.refresh();
              },
              icon: const Icon(Icons.check),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String? value) {
    // Fonction pour masquer la partie de l'e-mail entre la première et la dernière lettre avant '@'
    String _maskEmail(String? email) {
      if (email == null || !email.contains('@')) return email ?? '';

      final atIndex = email.indexOf('@');
      final firstLetter = email[0];
      final lastLetterBeforeAt = email[atIndex - 1];

      // Masquer tout entre la première lettre et la dernière avant '@'
      String maskedEmail = firstLetter +
          '*' * (atIndex - 2) +
          lastLetterBeforeAt +
          email.substring(atIndex);

      return maskedEmail;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: TextEditingController(text: _maskEmail(value)),
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
