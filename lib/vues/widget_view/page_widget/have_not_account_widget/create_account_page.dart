import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/create_account.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/authentification_process.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/my_text_fied.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatelessWidget {
  final controller = CreateAccountController();
  //final FirebaseFirestore firestore;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final LoadUserController _loadUserController = LoadUserController();

  CreateAccountPage({
    super.key,
    // required this.firestore,
  });

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
              children: [
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.only(bottom: 40),
                  width: width / 4,
                  child: Image.asset(
                    "images/assets/CK.png",
                  ),
                ),
                MyTextStyle.lotName("Créer votre compte ", Colors.black54,
                    SizeFont.header.size),
                const SizedBox(height: 10),
                MyTextField(
                  autofocus: false,
                  hintText: "Email",
                  osbcureText: false,
                  controller: _emailController,
                  padding: 0,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  autofocus: false,
                  hintText: "Mot de passe",
                  osbcureText: true,
                  controller: _passwordController,
                  padding: 0,
                ),
                const SizedBox(height: 15),
                Visibility(
                  visible: _passwordController.text != "",
                  child: MyTextField(
                    autofocus: false,
                    hintText: "Confirmez le Mot de passe",
                    osbcureText: true,
                    controller: _confirmPasswordController,
                    padding: 0,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(width, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      backgroundColor: Color.fromRGBO(72, 119, 91, 1.0),
                    ),
                    onPressed: () {
                      CreateAccountController.createAccount(
                        context,
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        _confirmPasswordController.text.trim(),
                        FirebaseFirestore.instance,
                      );
                    },
                    child: MyTextStyle.lotName(
                        "Continuer", Colors.white, SizeFont.h2.size),
                  ),
                ),
                const SizedBox(height: 50),
                DividerWithText(),
                const SizedBox(height: 20),
                WidgetConnectionTiers(
                    context,
                    28,
                    42,
                    FirebaseFirestore.instance,
                    _loadUserController,
                    width,
                    "images/assets/logo_login/google.png",
                    "Google"),
                // Add other sign-in options here
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget for Divider with Text
  Widget DividerWithText() {
    return Row(
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
          child: MyTextStyle.postDesc("Ou", SizeFont.h2.size, Colors.black54),
        ),
        Expanded(
          child: Divider(
            thickness: 0.5,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget WidgetConnectionTiers(context, double radius, double space, firestore,
      loadUserController, double width, String pathIcon, String provider) {
    return Padding(
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
                loadUserController: loadUserController,
              ).fluttLogInWithGoogle();
            },
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: radius,
                  height: radius,
                  child: Image.asset(pathIcon),
                ),
                SizedBox(
                  width: space,
                ),
                MyTextStyle.postDesc("S'inscrire avec $provider",
                    SizeFont.h3.size, Colors.black54)
              ],
            )));
  }
}
