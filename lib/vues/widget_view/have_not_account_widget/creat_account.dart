import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/authentification_process.dart';
import 'package:connect_kasa/controllers/widgets_controllers/progress_widget.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/components/my_text_fied.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/creat_account.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step0.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class CreatAccount extends StatelessWidget {
  final FirebaseFirestore firestore;
  final LoadUserController _loadUserController = LoadUserController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _MdPController = TextEditingController();

  CreatAccount({super.key, required this.firestore});
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
                  height: 20,
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 40),
                  width: width / 4,
                  child: Image.asset(
                    "images/assets/CK.png",
                    
                    //fit: BoxFit.fitWidth,
                  ),
                ),
                MyTextStyle.lotName(
                        "Créer un compte", Colors.black87, SizeFont.header.size),
                const SizedBox(
                  height: 10,
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
                    child: MyTextStyle.lotName(
                        "Continuer > ", Colors.white, SizeFont.h1.size),
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
                      child: MyTextStyle.postDesc("Ou",
                          SizeFont.h1.size, Colors.black54),
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
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                         minimumSize: Size(width, 50),
                        ),
                        onPressed: () {
                          AuthentificationProcess(
                            context: context,
                            firestore: firestore,
                            loadUserController: _loadUserController,
                          ).fluttLogInWithGoogle();
                        },
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                          Container(
                            width: 30,
                            height: 30,
                            child: Image.asset(
                                  "images/assets/logo_login/google.png"),
                          ),
                          SizedBox(width: 40,),
                          
                                MyTextStyle.postDesc("S'inscrire avec Google",
                          SizeFont.h3.size, Colors.black54)],) )
                    ),
                      Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                         minimumSize: Size(width, 50),
                        ),
                        onPressed: () {
                          AuthentificationProcess(
                            context: context,
                            firestore: firestore,
                            loadUserController: _loadUserController,
                          ).fluttLogInWithGoogle();
                        },
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                          Container(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                                  "images/assets/logo_login/apple-logo.png"),
                          ),
                          SizedBox(width: 30,),
                                MyTextStyle.postDesc("S'inscrire avec Apple",
                          SizeFont.h3.size, Colors.black54)],) )
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                         minimumSize: Size(width, 50),
                        ),
                        onPressed: () {
                          AuthentificationProcess(
                            context: context,
                            firestore: firestore,
                            loadUserController: _loadUserController,
                          ).fluttLogInWithGoogle();
                        },
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                          Container(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                                  "images/assets/logo_login/microsoft.png"),
                          ),
                          SizedBox(width: 30,),
                                MyTextStyle.postDesc("S'inscrire avec Microsoft",
                          SizeFont.h3.size, Colors.black54)],) )
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
