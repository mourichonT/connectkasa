import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class TakePictureScreen extends StatefulWidget {
  final String idType;

  const TakePictureScreen(
      {Key? key, required this.camera, required this.idType})
      : super(key: key);

  final CameraDescription camera;

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final double widthCard = 1004 / 3;
  final double heightCard = 638 / 3;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.ultraHigh,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
          title: MyTextStyle.lotName(
              "Positionner votre ${widget.idType}", Colors.black54)),
      body: Container(
        // Container pour l'arrière-plan
        color: Colors.black, // Noir avec opacité de 0.5
        child: Stack(
          children: <Widget>[
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: widthCard, // Adjust as needed
                height: heightCard, // Adjust as needed
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white, // Change color as needed
                      width: 5,
                      // Adjust as needed
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(
          height: 65,
          width: 65,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                XFile imageFile = await _controller.takePicture();
                if (!context.mounted) return;

                // Convertir XFile en Uint8List
                Uint8List bytes = await imageFile.readAsBytes();

                // Charger l'image avec la bibliothèque d'image
                img.Image image = img.decodeImage(bytes)!;

                // Récupérer les coordonnées de la zone de l'overlay
                int overlayWidth = widthCard.toInt(); // Largeur de l'overlay
                int overlayHeight = heightCard.toInt(); // Hauteur de l'overlay
                int overlayX =
                    (image.width - overlayWidth) ~/ 2; // X de l'overlay
                int overlayY =
                    (image.height - overlayHeight) ~/ 2; // Y de l'overlay

                // Recadrer l'image selon la zone de l'overlay
                img.Image croppedImage = img.copyCrop(
                  image,
                  x: overlayX,
                  y: overlayY,
                  width: overlayWidth * 2,
                  height: overlayHeight * 2,
                );

                print(
                    'Dimensions de l\'image capturée : ${image.width} x ${image.height}');
                print(
                    'Position de l\'image capturée : ${overlayY} x ${overlayX}');
                print(
                    'Position de l\'image recadrée : ${overlayWidth} x ${overlayHeight}');
                print(
                    'Dimensions de l\'image recadrée : ${croppedImage.width} x ${croppedImage.height}');

                // Enregistrer l'image recadrée dans un fichier
                File croppedFile =
                    File(imageFile.path.replaceAll('.jpg', '_cropped.jpg'));
                croppedFile.writeAsBytesSync(img.encodeJpg(croppedImage));

                // Naviguer vers l'écran d'affichage de l'image
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(
                      imagePath: croppedFile.path,
                    ),
                  ),
                );
              } catch (e) {
                print(e);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60, // Ajustez la taille selon vos besoins
                  height: 60, // Ajustez la taille selon vos besoins
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white, // Couleur de la bordure blanche
                      width: 2, // Épaisseur de la bordure
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 50, // Ajustez la taille selon vos besoins
                    height: 50, // Ajustez la taille selon vos besoins
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}
