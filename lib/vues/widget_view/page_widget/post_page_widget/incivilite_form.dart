import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/core/utils/media_type.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:flutter/material.dart';

class InciviliteForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => InciviliteFormState();
  final Lot preferedLot;
  final String racineFolder;
  final String uid;
  final String idPost;
  final Function(String) updateUrl; // Fonction pour mettre à jour imagePath
  final String folderName;

  const InciviliteForm({
    super.key,
    required this.preferedLot,
    required this.racineFolder,
    required this.uid,
    required this.idPost,
    required this.updateUrl,
    required this.folderName,
  });
}

class InciviliteFormState extends State<InciviliteForm> {
  late List<String> itemsType;
  late TextEditingController textEditingController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
  }

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  String imagePath = "";
  bool isVideoMedia = false;
  String fileName = '';
  bool anonymPost = true;

  void updateItem(String updatedElement) {
    setState(() {});
  }

  void updateBool(bool updatedBool) {
    setState(() {
      anonymPost = updatedBool;
    });
  }

  void downloadImagePath(String downloadUrl) {
    setState(() {
      widget.updateUrl(downloadUrl);
      imagePath = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CameraOrFiles(
                racineFolder: widget.racineFolder,
                residence: widget.preferedLot.residenceId,
                folderName: widget.folderName,
                title: title.text,
                onImageUploaded:
                    downloadImagePath, // Passer la fonction de rappel
                allowVideo: true,
                onExtensionResolved: (ext) =>
                    setState(() => isVideoMedia = isVideoExtension(ext)),
                cardOverlay: false,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextFieldWidget(
                  label: "Titre",
                  text: "Définissez un titre pour votre post",
                  controller: title,
                  isEditable: true,
                  minLines: 1,
                  maxLines: 1,
                ),

                /// 📝 **Description (Remplacé par CustomTextFieldWidget)**
                CustomTextFieldWidget(
                    label: "Description",
                    controller: desc,
                    isEditable: true,
                    minLines: 6,
                    maxLines: 6,
                    text: "Donnez des précisions sur la déclaration"),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyTextStyle.lotDesc("Publier anonymement?  ", SizeFont.h3.size),
                Switch(
                  thumbIcon: thumbIcon,
                  value: anonymPost,
                  onChanged: (bool value) {
                    setState(() {
                      anonymPost = value;
                      updateBool(anonymPost);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            Center(
              child: ButtonAdd(
                color: Theme.of(context).primaryColor,
                text: "Soumettre",
                horizontal: 20,
                vertical: 5,
                size: SizeFont.h2.size,
                function: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          await SubmitPostController.submitForm(
                            uid: widget.uid,
                            idPost: widget.idPost,
                            selectedLabel: widget.folderName,
                            imagePath: imagePath,
                            isVideo: isVideoMedia,
                            title: title,
                            desc: desc,
                            anonymPost: anonymPost,
                            docRes: widget.preferedLot.residenceId,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text("Erreur lors de l'envoi : $e"),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
              ),
            ),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      ],
    );
  }
}
