import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/auth_controller.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/authentification_process.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/my_text_fied.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/create_account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPageView extends StatelessWidget {
  final FirebaseFirestore firestore;
  final LoadUserController _loadUserController = LoadUserController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _MdPController = TextEditingController();

  LoginPageView({super.key, required this.firestore});
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(
                  height: 80,
                ),
                Image.asset(
                  "images/assets/logoCKvertconnectKasa.png",
                  width: width / 1.5,
                ),
                const SizedBox(
                  height: 85,
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            fixedSize: Size(width, 60),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {
                            AuthentificationProcess(
                              context: context,
                              firestore: firestore,
                              loadUserController: _loadUserController,
                            ).fluttLogInWithGoogle();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: Colors.white,
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  child: Image.asset(
                                    "images/assets/logo_login/google.png",
                                    width: width,
                                  ),
                                ),
                              ),
                              MyTextStyle.lotName(
                                "Continuer avec Google",
                                Colors.black54,
                                SizeFont.h2.size,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: MyTextStyle.postDesc(
                          "Ou", SizeFont.h3.size, Colors.black54),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                MyTextField(
                  autofocus: false,
                  hintText: "Email",
                  osbcureText: false,
                  controller: _emailController,
                  padding: 0,
                ),
                const SizedBox(
                  height: 15,
                ),
                MyTextField(
                  autofocus: false,
                  hintText: "Mot de passe",
                  osbcureText: true,
                  controller: _MdPController,
                  padding: 0,
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final email = _emailController.text.trim();
                          final authController = AuthController();
                          await authController.sendPasswordResetEmail(
                            context: context,
                            email: email,
                          );
                        },
                        child: MyTextStyle.postDesc("Mot de passe oublié?",
                            SizeFont.h3.size, Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 60,
                ),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        fixedSize: Size(width, 50),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        backgroundColor: Color.fromRGBO(72, 119, 91, 1.0)),
                    onPressed: () {
                      SignIn(
                          context, _emailController.text, _MdPController.text);
                    },
                    child: MyTextStyle.lotName(
                      "Connexion",
                      Colors.white,
                      SizeFont.h1.size,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyTextStyle.postDesc(
              "Pas encore membre?",
              SizeFont.h3.size,
              Colors.black54,
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAccount(firestore: firestore),
                  ),
                );
              },
              child: MyTextStyle.login(
                "Enregistrez-vous",
                SizeFont.h3.size,
                Color.fromRGBO(72, 119, 91, 1.0),
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future SignIn(BuildContext context, String email, String password) async {
    try {
      UserCredential? userCredentials;
      userCredentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      AuthentificationProcess(
        context: context,
        firestore: firestore,
        loadUserController: _loadUserController,
      ).SignInWithMail(userCredentials);
    } on FirebaseAuthException catch (ex) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("L'email et/ou le mot de passe sont incorrect"),
          backgroundColor: Colors.red, // Optionnel : couleur de fond
          duration: Duration(seconds: 3), // Optionnel : durée d'affichage
        ),
      );

      print("error occured due to ${ex.code.toString()}");
    }
  }
}
