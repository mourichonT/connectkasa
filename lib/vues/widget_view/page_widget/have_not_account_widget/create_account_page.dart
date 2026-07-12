import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/create_account.dart';
import 'package:konodal/controllers/features/load_user_controller.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/widgets_controllers/authentification_process.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/widget_view/components/my_text_fied.dart';
import 'package:flutter/material.dart';
import 'package:konodal/core/utils/app_logger.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final controller = CreateAccountController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final LoadUserController _loadUserController = LoadUserController();

  bool showConfirmPassword = false;
  bool _isGoogleSigningIn = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_passwordController.text.isNotEmpty != showConfirmPassword) {
        setState(() {
          showConfirmPassword = _passwordController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(() {
      if (_passwordController.text.isNotEmpty != showConfirmPassword) {
        setState(() {
          showConfirmPassword = _passwordController.text.isNotEmpty;
        });
      }
    });
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 60, bottom: 60),
                width: width / 1.5,
                child: Image.asset(
                    "images/assets/logo_by_colors/logoVert72.119.91.png"),
              ),
              MyTextStyle.lotName(
                  "Créer votre compte", Colors.black54, SizeFont.header.size),
              const SizedBox(height: 40),
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
              if (showConfirmPassword)
                MyTextField(
                  autofocus: false,
                  hintText: "Confirmez le mot de passe",
                  osbcureText: true,
                  controller: _confirmPasswordController,
                  padding: 0,
                ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(width, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  backgroundColor: const Color.fromRGBO(72, 119, 91, 1.0),
                ),
                onPressed: () {
                  if (mounted) {
                    CreateAccountController.createAccount(
                      context,
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      _confirmPasswordController.text.trim(),
                      FirebaseFirestore.instance,
                    );
                  }
                },
                child: MyTextStyle.lotName(
                    "Continuer", Colors.white, SizeFont.h2.size),
              ),
              const SizedBox(height: 50),
              dividerWithText(),
              const SizedBox(height: 20),
              widgetConnectionTiers(
                context,
                28,
                42,
                FirebaseFirestore.instance,
                _loadUserController,
                width,
                "images/assets/logo_login/google.png",
                "Google",
                _isGoogleSigningIn,
                (value) => setState(() => _isGoogleSigningIn = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dividerWithText() {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 0.5, color: Colors.grey[400])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: MyTextStyle.postDesc("Ou", SizeFont.h2.size, Colors.black54),
        ),
        Expanded(child: Divider(thickness: 0.5, color: Colors.grey[400])),
      ],
    );
  }

  Widget widgetConnectionTiers(
    BuildContext context,
    double radius,
    double space,
    FirebaseFirestore firestore,
    LoadUserController loadUserController,
    double width,
    String pathIcon,
    String provider,
    bool isSigningIn,
    void Function(bool) setSigningIn,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          minimumSize: Size(width, 50),
        ),
        onPressed: isSigningIn
            ? null
            : () async {
                setSigningIn(true);
                final authProcess = AuthentificationProcess(
                  context: context,
                  firestore: firestore,
                  loadUserController: loadUserController,
                );

                try {
                  await authProcess.fluttLogInWithGoogle();
                } catch (e) {
                  appLog("Erreur lors de l'authentification Google: $e");
                } finally {
                  if (mounted) setSigningIn(false);
                }
              },
        child: isSigningIn
            ? SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                children: [
                  SizedBox(
                      width: radius,
                      height: radius,
                      child: Image.asset(pathIcon)),
                  SizedBox(width: space),
                  MyTextStyle.postDesc(
                    "S'inscrire avec $provider",
                    SizeFont.h3.size,
                    Colors.black54,
                  ),
                ],
              ),
      ),
    );
  }
}
