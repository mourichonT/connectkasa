import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_user.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/legal_texts/info_centre.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InfoPersoPageModify extends StatefulWidget {
  final User user;
  final String uid;
  final Color color;
  final String email;
  final Function refresh;
  final String idLot;

  const InfoPersoPageModify({
    super.key,
    required this.uid,
    required this.color,
    required this.email,
    required this.refresh,
    required this.user,
    required this.idLot,
  });

  @override
  State<InfoPersoPageModify> createState() => _InfoPersoPageModifyState();
}

class _InfoPersoPageModifyState extends State<InfoPersoPageModify> {
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController birthday = TextEditingController();
  TextEditingController pseudo = TextEditingController();
  TextEditingController bio = TextEditingController();
  TextEditingController profession = TextEditingController();
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
    DateTime birthDate =
        (widget.user.birthday).toDate().toLocal();
    birthday.text = DateFormat('dd/MM/yyyy').format(birthDate);
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
                  SubmitUser.updateUser(
                    context: context,
                    uid: widget.uid,
                    field: field,
                    label: label,
                    value: capitalizeFirstLetter(value),
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
                  SubmitUser.updateUser(
                    context: context,
                    uid: widget.uid,
                    field: field,
                    label: label,
                    value: capitalizeFirstLetter(value),
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
