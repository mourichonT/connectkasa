import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_user.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/legal_texts/privacy_policy.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/Privacy_politic_widget.dart';
import 'package:flutter/material.dart';

class PrivatePolicyPage extends StatefulWidget {
  final User user;
  final Function refresh;

  const PrivatePolicyPage(
      {super.key, required this.user, required this.refresh});

  @override
  State<PrivatePolicyPage> createState() => _PrivatePolicyPageState();
}

class _PrivatePolicyPageState extends State<PrivatePolicyPage> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.user.privacyPolicy;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rafraîchissement des données à chaque retour sur la page
    widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: MyTextStyle.lotName(
          'Politique de Confidentialité',
          Colors.black87,
          SizeFont.h1.size,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              PrivatePolicyWidget(),
              SizedBox(height: 20),

              /// ✅ La checkbox sous la card
              CheckboxListTile(
                value: _isChecked,
                onChanged: (value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
                title: Text(
                  "J'ai lu et j'accepte la politique de confidentialité.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecked
                      ? () {
                          SubmitUser.UpdateUser(
                            context: context,
                            uid: widget.user.uid,
                            field: 'privacyPolicy',
                            label: "Politique de Confidentialité",
                            newBool: _isChecked,
                          );
                          widget.refresh();
                          // Utilisation de Future.delayed pour différer le pop
                          Future.delayed(Duration(milliseconds: 300), () {
                            if (mounted) {
                              // Vérifie que le widget est toujours monté
                              Navigator.pop(context);
                            }
                          });
                        }
                      : null, // Désactivé si pas coché
// Désactivé si pas coché
                  child: Text("Continuer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isChecked
                        ? Theme.of(context).primaryColor
                        : Colors.grey, // Couleur dynamique
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
