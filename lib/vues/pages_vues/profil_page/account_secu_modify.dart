import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_user.dart';
import 'package:konodal/controllers/widgets_controllers/account_deletion_controller.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/legal_texts/info_centre.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class AccountSecuPageModify extends StatefulWidget {
  final User user;
  final String uid;
  final Color color;
  final String email;
  final Function refresh;
  final String idLot;

  const AccountSecuPageModify({
    super.key,
    required this.uid,
    required this.color,
    required this.email,
    required this.refresh,
    required this.user,
    required this.idLot,
  });

  @override
  State<AccountSecuPageModify> createState() =>
      _AccountSecuPageModifyState();
}

class _AccountSecuPageModifyState extends State<AccountSecuPageModify> {
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController pseudo = TextEditingController();
  TextEditingController bio = TextEditingController();
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
            "Compte & sécurité", Colors.black87, SizeFont.h1.size),
      ),
      bottomSheet: Container(
          color: Theme.of(context)
              .indicatorColor, // Changez cette couleur selon vos besoins
          padding: const EdgeInsets.symmetric(vertical: 25),
          child:
              SizedBox(
                child: ButtonAdd(
                  function: () => AccountDeletionController(
                    context: context,
                    uid: widget.uid,
                    email: widget.email,
                  ).confirmDeleteAccount(),
                  color: Colors.red[800]!,
                  icon: Icons.clear,
                  text: "Supprimer le compte",
                  horizontal: 20,
                  vertical: 10,
                  size: SizeFont.h3.size,
                ),
              ),
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
                              SubmitUser.updateUser(
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

  Widget _buildReadOnlyTextField(String label, String? value) {
    // Fonction pour masquer la partie de l'e-mail entre la première et la dernière lettre avant '@'
    String maskEmail(String? email) {
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
        controller: TextEditingController(text: maskEmail(value)),
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
      if (!mounted) return;
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
      if (!mounted) return;
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
