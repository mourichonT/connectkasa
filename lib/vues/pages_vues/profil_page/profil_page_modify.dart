import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class ProfilPageModify extends StatefulWidget {
  final String uid;
  final Color color;
  final String email;

  const ProfilPageModify({
    super.key,
    required this.uid,
    required this.color,
    required this.email,
  });

  @override
  _ProfilPageModifyState createState() => _ProfilPageModifyState();
}

class _ProfilPageModifyState extends State<ProfilPageModify> {
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController pseudo = TextEditingController();
  TextEditingController bio = TextEditingController();
  DataBasesUserServices userServices = DataBasesUserServices();
  User? user;

  FocusNode nameFocusNode = FocusNode();
  FocusNode surnameFocusNode = FocusNode();
  FocusNode pseudoFocusNode = FocusNode();
  FocusNode bioFocusNode = FocusNode();

  bool privateAccount = true;

  @override
  void initState() {
    super.initState();

    _loadUser(widget.uid);

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
            "Modifier le profil", Colors.black87, SizeFont.h1.size),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProfilTile(widget.uid, 45, 40, 45, false),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: MyTextStyle.lotName("Modifier la photo",
                              widget.color ?? Colors.black87, SizeFont.h3.size),
                        ),
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 20,
                          color: widget.color,
                        ),
                      ],
                    ),
                    _buildReadOnlyTextField('Email', widget.email),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: ElevatedButton(
                        onPressed: () => resetPassword(widget.email),
                        child: const Text('Réinitialiser le mot de passe'),
                      ),
                    ),
                    _buildReadOnlyTextField('Nom', name.text),
                    _buildReadOnlyTextField('Prénom', surname.text),
                    _buildModifyTextField("Pseudo", pseudo, pseudoFocusNode),
                    _buildModifyTextField("Biographie", bio, bioFocusNode,
                        maxLines: 5, minLines: 2),
                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyTextStyle.lotDesc("Compte privé", SizeFont.h3.size,
                              FontStyle.normal),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: privateAccount,
                              onChanged: (bool value) {
                                setState(() {
                                  privateAccount = value;
                                  // Met à jour l'état du compte privé
                                  user!.private = value;
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

  Widget _buildModifyTextField(
      String label, TextEditingController controller, FocusNode focusNode,
      {int maxLines = 1, int minLines = 1}) {
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
                focusNode.unfocus();
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

  Future<void> _loadUser(String uid) async {
    if (uid.isNotEmpty) {
      user = await userServices.getUserById(uid);
      if (user != null) {
        name.text = user!.name;
        surname.text = user!.surname;
        pseudo.text = user!.pseudo!;
        bio.text = user!.bio!;
        privateAccount = user!.private; // Met à jour l'état du compte privé
      }
      setState(() {});
    }
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
