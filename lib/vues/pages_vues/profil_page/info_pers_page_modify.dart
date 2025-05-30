import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_user.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/legal_texts/info_centre.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/vues/pages_vues/profil_page/profile_page_view.dart';
import 'package:connect_kasa/vues/widget_view/components/button_add.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InfoPersoPageModify extends StatefulWidget {
  final User user;
  final String uid;
  final Color color;
  final String email;
  final Function refresh;
  final String refLot;

  const InfoPersoPageModify({
    super.key,
    required this.uid,
    required this.color,
    required this.email,
    required this.refresh,
    required this.user,
    required this.refLot,
  });

  @override
  _InfoPersoPageModifyState createState() => _InfoPersoPageModifyState();
}

class _InfoPersoPageModifyState extends State<InfoPersoPageModify> {
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController birthday = TextEditingController();
  TextEditingController pseudo = TextEditingController();
  TextEditingController bio = TextEditingController();
  TextEditingController profession = TextEditingController();
  DataBasesUserServices userServices = DataBasesUserServices();
  String? profilPic = "";

  FocusNode nameFocusNode = FocusNode();
  FocusNode surnameFocusNode = FocusNode();
  FocusNode birthdayFocusNode = FocusNode();
  FocusNode pseudoFocusNode = FocusNode();
  FocusNode bioFocusNode = FocusNode();
  FocusNode professionFocusNode = FocusNode();

  bool privateAccount = true;

  @override
  void initState() {
    super.initState();

    // Initialisation avec les valeurs de widget.user
    name.text = widget.user.name;
    surname.text = widget.user.surname;
    pseudo.text = widget.user.pseudo!;
    if (widget.user.birthday != null) {
      DateTime birthDate =
          (widget.user.birthday as Timestamp).toDate().toLocal();
      birthday.text = DateFormat('dd/MM/yyyy').format(birthDate);
    }
    bio.text = widget.user.bio!;
    profilPic = widget.user.profilPic;
    privateAccount = widget.user.private; // Met à jour l'état du compte privé

    nameFocusNode.addListener(() => setState(() {}));
    surnameFocusNode.addListener(() => setState(() {}));
    pseudoFocusNode.addListener(() => setState(() {}));
    bioFocusNode.addListener(() => setState(() {}));
    professionFocusNode.addListener(() => setState(() {}));
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
            "Modifier vos informations", Colors.black87, SizeFont.h1.size),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              CustomTextFieldWidget(
                label: "Nom",
                value: name
                    .text, // Assurez-vous que `name` est un TextEditingController
                isEditable: false,
              ),
              CustomTextFieldWidget(
                label: "Prénom",
                value: surname
                    .text, // Assurez-vous que `name` est un TextEditingController
                isEditable: false,
              ),
              CustomTextFieldWidget(
                label: 'Date de naissance',
                value: birthday
                    .text, // Assurez-vous que `name` est un TextEditingController
                isEditable: false,
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 10, bottom: 30, top: 5, right: 10),
                child: MyTextStyle.lotDesc(
                  InfoCentre.changeNameforbidden,
                  SizeFont.para.size,
                  FontStyle.italic,
                  FontWeight.normal,
                ),
              ),
              CustomTextFieldWidget(
                label: "Pseudo",
                field: "pseudo",
                controller: pseudo,
                focusNode: pseudoFocusNode,
                isEditable: true,
                onSubmit: (field, label, value) {
                  SubmitUser.UpdateUser(
                    context: context,
                    uid: widget.uid,
                    field: field,
                    label: label,
                    value: value,
                  );
                  widget.refresh();
                },
                refresh: () => setState(() {}),
              ),
              CustomTextFieldWidget(
                label: "Biographie",
                field: "bio",
                controller: bio,
                focusNode: bioFocusNode,
                isEditable: true,
                onSubmit: (field, label, value) {
                  SubmitUser.UpdateUser(
                    context: context,
                    uid: widget.uid,
                    field: field,
                    label: label,
                    value: value,
                  );
                  widget.refresh();
                },
                refresh: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
