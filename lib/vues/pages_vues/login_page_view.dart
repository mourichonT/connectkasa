import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/authentification_process.dart';
import 'package:connect_kasa/vues/components/my_text_fied.dart';
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
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: 80,
                ),
                Image.asset(
                  "images/assets/logoCKvertconnectKasa.png",
                  width: width / 1.5,
                  //fit: BoxFit.fitWidth,
                ),
                const SizedBox(
                  height: 45,
                ),
                MyTextField(
                  hintText: "Email",
                  osbcureText: false,
                  controller: _emailController,
                  padding: 0,
                ),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                  hintText: "Mot de passe",
                  osbcureText: true,
                  controller: _MdPController,
                  padding: 0,
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      onPressed: () {},
                      child: MyTextStyle.postDesc(
                          "Mot de passe oublié?", 14, Colors.black54),
                    ),
                  ]),
                ),
                const SizedBox(
                  height: 60,
                ),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(width, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      SignIn(
                          context, _emailController.text, _MdPController.text);
                    },
                    child: MyTextStyle.lotName("Connexion", Colors.white, 20),
                  ),
                ),
                const SizedBox(
                  height: 50,
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
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: MyTextStyle.postDesc(
                          "Ou continuer avec", 15, Colors.black54),
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
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        AuthentificationProcess(
                          context: context,
                          firestore: firestore,
                          loadUserController: _loadUserController,
                        ).LogInWithGoogle();
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.black12,
                        radius: 35,
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              "images/assets/logo_login/google.png",
                              width: width / 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.black12,
                      radius: 35,
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          child: Image.asset(
                            "images/assets/logo_login/apple-logo.png",
                            width: width / 1.5,
                          ),
                        ),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.black12,
                      radius: 35,
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          child: Image.asset(
                            "images/assets/logo_login/microsoft.png",
                            width: width / 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
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
              MyTextStyle.postDesc("Pas encore membre?", 15, Colors.black54),
              SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  //Navigator.push(
                  //context,
                  //MaterialPageRoute(
                  // builder: (context) => ProgressWidget(newUser: user.uid),
                  //Step0(newUser: user.uid),
                  //),
                  //);
                },
                child: MyTextStyle.login("Enregistrez-vous", 15,
                    Theme.of(context).primaryColor, FontWeight.bold),
              ),
            ],
          )),
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
      print("error occured due to ${ex.code.toString()}");
    }
  }
}
