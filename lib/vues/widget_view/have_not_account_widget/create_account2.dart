import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/create_account.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/widgets_controllers/authentification_process.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';

class CreateAccount extends StatelessWidget {
  final controller = CreateAccountController();
  final FirebaseFirestore firestore;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final LoadUserController _loadUserController = LoadUserController();

  CreateAccount({super.key, required this.firestore});

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
                 MyTextStyle.lotName(
                        "Créer votre compte ", Colors.black54, SizeFont.header.size),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _emailController,
                  hintText: "Email",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _passwordController,
                  hintText: "Mot de passe",
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                 Visibility(
                  visible: _passwordController.text!=null,
                  child: 
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: "Confirmez votre mot de passe",
                    obscureText: true,
                  )
                ),
                const SizedBox(height: 15),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(width, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
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
                WidgetConnectionTiers (context,28,42, firestore, _loadUserController, width, "images/assets/logo_login/google.png", "Google"),
                WidgetConnectionTiers (context,40,30, firestore, _loadUserController, width, "images/assets/logo_login/apple-logo.png", "Apple"),
                WidgetConnectionTiers (context,40,30, firestore, _loadUserController, width, "images/assets/logo_login/microsoft.png", "Microsoft")

                // Add other sign-in options here
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget Helper for Text Fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

//   Future<void> _createAccount(
//     BuildContext context, String email, String password) async {
//   if (email.isEmpty || password.isEmpty) {
//     _showSnackbar(context, "Veuillez remplir tous les champs.");
//     return;
//   }

//   // Check password complexity
//   if (!_isPasswordStrong(password)) {
//     _showSnackbar(context,
//         "Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre, et un caractère spécial.");
//     return;
//   }

//   try {
//     // Create user with email and password
//     UserCredential userCredential = await FirebaseAuth.instance
//         .createUserWithEmailAndPassword(email: email, password: password);

//     // Initialize UserTemp object
//     UserTemp newUser = UserTemp(
//       email: email,
//       createdDate: Timestamp.now(),
//       name: "", // Replace with actual input from a form
//       surname: "", // Replace with actual input
//       pseudo: "", // Replace with actual input
//       uid: userCredential.user!.uid,
//       approved: false,
//       //statutResident: "", // Replace with actual logic
//       typeLot: "", // Replace with actual logic
//       //compagnyBuy: false, // Replace with actual logic
//     );

//     // Add UserTemp data to Firestore
//     await firestore.collection('User').doc(userCredential.user!.uid).set(
//           newUser.toMap(),
//         );

//     // Navigate to next screen or display success message
//     _showSnackbar(context, "Compte créé avec succès !");
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ProgressWidget(
//           userId: userCredential.user!.uid,
//           emailUser: email,
//         ),
//       ),
//     );
//   } on FirebaseAuthException catch (e) {
//     String errorMessage;
//     switch (e.code) {
//       case 'email-already-in-use':
//         errorMessage = "Cet email est déjà utilisé.";
//         break;
//       case 'invalid-email':
//         errorMessage = "L'adresse email est invalide.";
//         break;
//       case 'weak-password':
//         errorMessage = "Le mot de passe est trop faible.";
//         break;
//       default:
//         errorMessage = "Une erreur est survenue. Veuillez réessayer.";
//     }
//     _showSnackbar(context, errorMessage);
//   } catch (e) {
//     _showSnackbar(context, "Erreur inattendue : ${e.toString()}");
//   }
// }

// /// Validate password strength
// bool _isPasswordStrong(String password) {
//   // Regular expression for strong password
//   final regex = RegExp(
//     r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$',
//   );

//   return regex.hasMatch(password);
// }

// bool _confirmPaswword(String password, String confirmPaswword){

//   if (password == confirmPaswword){
//     return true;
//   }
// return false;
// }
//   /// Helper method to show snackbars
//   void _showSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
// }

/// Widget for Divider with Text
Widget DividerWithText () {
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
                      child: MyTextStyle.postDesc("Ou",
                          SizeFont.h2.size, Colors.black54),
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

  Widget WidgetConnectionTiers (context, double radius, double space, firestore, loadUserController, double width, String pathIcon, String provider){
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
                            child: Image.asset(
                                  pathIcon),
                          ),
                          SizedBox(width: space,),
                          
                                MyTextStyle.postDesc("S'inscrire avec $provider",
                          SizeFont.h3.size, Colors.black54)],) )
                    );
  }

  

}