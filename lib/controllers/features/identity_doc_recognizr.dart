import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';

class IdentityDocumentRecognizer extends StatefulWidget {
  @override
  _IdentityDocumentRecognizerState createState() =>
      _IdentityDocumentRecognizerState();
}

class _IdentityDocumentRecognizerState
    extends State<IdentityDocumentRecognizer> {
  File? _image;
  String _recognizedText = "";
  String _name = "";
  String _dob = ""; // Date of Birth
  String _firstName = "";

  // Méthode pour choisir une image à partir de la galerie ou de la caméra
  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _recognizeText();
    }
  }

  // Méthode pour reconnaître le texte à partir de l'image choisie
  Future<void> _recognizeText() async {
    if (_image == null) return;

    // Utiliser FlutterTesseractOcr pour reconnaître le texte
    String text = await FlutterTesseractOcr.extractText(_image!.path);
    setState(() {
      _recognizedText = text;
    });

    // Analyser le texte pour extraire les informations
    _extractInformation(text);
  }

  // Méthode pour extraire le nom, prénom et date de naissance à partir du texte
  void _extractInformation(String text) {
    RegExp namePattern = RegExp(r'([A-Z][a-z]+\s[A-Z][a-z]+)');
    RegExp dobPattern =
        RegExp(r'(\d{2}/\d{2}/\d{4})'); // Exemple de date: 01/01/1990

    // Chercher le nom et prénom (exemple avec "John Doe")
    var nameMatch = namePattern.firstMatch(text);
    if (nameMatch != null) {
      setState(() {
        _name = nameMatch.group(0)!;
        List<String> nameParts = _name.split(" ");
        if (nameParts.length >= 2) {
          _firstName = nameParts[0];
          _name = nameParts[1];
        }
      });
    }

    // Chercher la date de naissance
    var dobMatch = dobPattern.firstMatch(text);
    if (dobMatch != null) {
      setState(() {
        _dob = dobMatch.group(0)!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reconnaissance Document d'Identité"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? Text("Aucune image sélectionnée.")
                : Image.file(_image!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Choisir une image"),
            ),
            SizedBox(height: 20),
            Text("Texte reconnu: $_recognizedText"),
            SizedBox(height: 20),
            Text("Nom: $_name"),
            Text("Prénom: $_firstName"),
            Text("Date de naissance: $_dob"),
          ],
        ),
      ),
    );
  }
}
