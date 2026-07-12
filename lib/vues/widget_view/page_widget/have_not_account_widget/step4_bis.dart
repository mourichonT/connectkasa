import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_user.dart';
import 'package:konodal/controllers/handlers/api/flutter_api.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/vues/pages_vues/no_approval_page.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/page_widget/privacy_politic_widget.dart';
import 'package:flutter/material.dart';

// Variante de Step4 pour un utilisateur sans résidence (step1.dart "Je n'ai
// pas encore de résidence") : ni justificatif de domicile (pas d'adresse à
// justifier), ni type de résident/bail (Step2/Step3 sautés) - seulement
// l'acceptation de la politique de confidentialité, puis validation directe
// de la demande.
class Step4Bis extends StatefulWidget {
  final String userId;
  final String emailUser;
  final String docTypeId;
  final String name;
  final String surname;
  final String pseudo;
  final Timestamp birthday;
  final String imagepathIDrecto;
  final String imagepathIDverso;
  final String idExtension;
  final String sex;
  final String nationality;
  final String placeOfBorn;
  final bool informationsCorrectes;
  final VoidCallback cancelDeletionTimer;
  final Function(bool) recupererInformationsStep4;

  const Step4Bis({
    super.key,
    required this.userId,
    required this.emailUser,
    required this.docTypeId,
    required this.name,
    required this.surname,
    required this.pseudo,
    required this.birthday,
    required this.imagepathIDrecto,
    required this.imagepathIDverso,
    required this.idExtension,
    required this.sex,
    required this.nationality,
    required this.placeOfBorn,
    required this.informationsCorrectes,
    required this.cancelDeletionTimer,
    required this.recupererInformationsStep4,
  });

  @override
  State<Step4Bis> createState() => _Step4BisState();
}

class _Step4BisState extends State<Step4Bis> {
  bool _isChecked = false;
  bool _isSubmitting = false;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    initUserFcmToken();
  }

  Future<void> initUserFcmToken() async {
    fcmToken = await FirebaseApi.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: MyTextStyle.lotName(
                  "Vous pourrez rattacher votre résidence plus tard depuis l'application. Il ne reste plus qu'à valider votre demande.",
                  Colors.black54,
                ),
              ),
              CheckboxListTile(
                value: _isChecked,
                onChanged: (value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
                title: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    MyTextStyle.postDesc(
                      " J'ai lu et j'accepte",
                      SizeFont.h3.size,
                      Colors.black54,
                    ),
                    TextButton(
                      onPressed: () {
                        showPrivacyPolicyPopup(context);
                      },
                      child: MyTextStyle.login(
                        "la politique de confidentialité.",
                        SizeFont.h3.size,
                        const Color.fromRGBO(72, 119, 91, 1.0),
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: Colors.white,
        padding: const EdgeInsets.all(2),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ButtonAdd(
              color: Theme.of(context)
                  .primaryColor
                  .withValues(alpha: _isChecked ? 1.0 : 0.5),
              text: "Valider la demande",
              horizontal: 20,
              vertical: 5,
              size: SizeFont.h2.size,
              function: (_isChecked && !_isSubmitting)
                  ? () async {
                      widget.recupererInformationsStep4(true);
                      setState(() => _isSubmitting = true);
                      try {
                        await SubmitUser.submitUser(
                          privacyPolicy: _isChecked,
                          emailUser: widget.emailUser,
                          name: widget.name,
                          surname: widget.surname,
                          sex: widget.sex,
                          nationality: widget.nationality,
                          placeOfborn: widget.placeOfBorn,
                          pseudo: widget.pseudo,
                          newUserId: widget.userId,
                          statutResident: '',
                          typeChoice: '',
                          intendedFor: '',
                          compagnyBuy: false,
                          residence: null,
                          lotId: null,
                          docTypeID: widget.docTypeId,
                          imagepathIDrecto: widget.imagepathIDrecto,
                          imagepathIDverso: widget.imagepathIDverso,
                          idExtension: widget.idExtension,
                          birthday: widget.birthday,
                          informationsCorrectes: widget.informationsCorrectes,
                          fcmToken: fcmToken,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                                'Erreur lors de la création du compte : $e'),
                          ),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      widget.cancelDeletionTimer();
                      // pushReplacement seul ne retire que ProgressWidget :
                      // CreateAccountPage reste en dessous dans la pile, donc
                      // le bouton "Revenir à la page de connexion" de
                      // NoApprovalPage (un simple pop) y renvoyait au lieu de
                      // LoginPageView. On vide toute la pile jusqu'à la route
                      // racine ('/' = LoginPageView, cf. main.dart) avant d'y
                      // empiler NoApprovalPage.
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const NoApprovalPage(),
                        ),
                        ModalRoute.withName('/'),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void showPrivacyPolicyPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: PrivatePolicyWidget(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
