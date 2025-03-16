import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
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

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
  }

  final ButtonStyle style =
      ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
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
  String fileName = '';
  bool anonymPost = true;

  void updateItem(String updatedElement) {
    String item = "";
    setState(() {
      item = updatedElement;
    });
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
            const Divider(),
            const SizedBox(
              height: 15,
            ),
            Center(
              child: CameraOrFiles(
                racineFolder: widget.racineFolder,
                residence: widget.preferedLot.residenceId,
                folderName: widget.folderName,
                title: title.text,
                onImageUploaded:
                    downloadImagePath, // Passer la fonction de rappel
                cardOverlay: false,
              ),
            ),
            const Divider(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotName(
                    "Titre : ", Colors.black87, SizeFont.h3.size),
                const SizedBox(
                  height: 15,
                ),
                TextField(
                  controller: title,
                  maxLines: 1,
                  decoration: const InputDecoration.collapsed(
                      hintText: "Saisissez le titre de votre post"),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotName(
                    "Description : ", Colors.black87, SizeFont.h3.size),
                const SizedBox(
                  height: 15,
                ),
                TextField(
                  controller: desc,
                  maxLines: 6,
                  decoration: const InputDecoration.collapsed(
                      hintText: "Saisissez une description"),
                ),
              ],
            ),
            const Divider(),
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
              child: ElevatedButton(
                style: style,
                onPressed: () {
                  SubmitPostController.submitForm(
                    uid: widget.uid,
                    idPost: widget.idPost,
                    selectedLabel: widget.folderName,
                    imagePath: imagePath,
                    title: title,
                    desc: desc,
                    anonymPost: anonymPost,
                    docRes: widget.preferedLot.residenceId,
                  );
                  Navigator.pop(context);
                },
                child: MyTextStyle.lotName("Soumettre",
                    Theme.of(context).primaryColor, SizeFont.h2.size),
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
