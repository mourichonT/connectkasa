import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageServices {
  final storageRef = FirebaseStorage.instance.ref();

  Future<String?> uploadImg(XFile file, String racine, String residence,
      String folderName, String fileName) async {
    try {
      // Récupérer l'extension du fichier original
      String extension = file.path.split('.').last;

      // Déterminer le type MIME en fonction de l'extension
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        // Ajoutez d'autres cas pour les extensions de fichiers supplémentaires si nécessaire
        default:
          throw UnsupportedError(
              'Extension de fichier non prise en charge: $extension');
      }

      // Construire le nom de fichier dans Firebase Storage avec l'extension récupérée
      final reference =
          storageRef.child("$racine/$residence/$folderName/$fileName");

      // Téléchargement du fichier vers Firebase Storage avec le type MIME spécifié
      final uploadTask = reference.putFile(
        File(file.path),
        SettableMetadata(contentType: mimeType),
      );

      // Récupération de l'URL du fichier une fois le téléchargement terminé
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Retourner l'URL du fichier téléchargé
      //print("URL = $downloadUrl");
      return downloadUrl;
    } catch (e) {
      // En cas d'erreur, imprimer l'erreur et retourner null
      print('Erreur lors du téléchargement du fichier: $e');
      return null;
    }
  }

  Future<String?> uploadDocFile(
    File file,
    String racine,
    String residence,
    String folderName,
    String fileName,
    String? reflot,
  ) async {
    try {
      // Récupérer l'extension du fichier
      final extension = file.path.split('.').last.toLowerCase();

      // Déterminer le type MIME
      final mimeType = switch (extension) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => throw UnsupportedError(
            'Extension de fichier non prise en charge: $extension'),
      };

      // Définir la référence du fichier
      final path = reflot != null && reflot.isNotEmpty
          ? "$racine/$residence/$folderName/$reflot/$fileName.$extension"
          : "$racine/$residence/$folderName/$fileName.$extension";

      final reference = storageRef.child(path);

      // Upload
      final uploadTask = reference.putFile(
        file,
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléchargement du fichier: $e');
      return null;
    }
  }

  Future<void> removeFolder(String racine, String folder) async {
    final Reference reference =
        FirebaseStorage.instance.ref().child("$racine/$folder");

    try {
      // Supprimer le dossier
      await reference.delete();

      print(
          'Le dossier du user temporaire $folder a été supprimé avec succès.');
    } catch (e) {
      print(
          'Erreur lors de la suppression du fichier : $e, sur le chemin $racine/$folder');
      // Gérer l'erreur ici
    }
  }

  Future<void> removeFile(
    String racine,
    String residence,
    String folderName, {
    String? reflot,
    String? url,
    String? idPost,
  }) async {
    String
        fileName; // Déclarer fileName en dehors des conditions if/else pour qu'il soit accessible plus tard

    // Extraire le nom du fichier à partir de l'URL
    if (url != null) {
      fileName = Uri.decodeFull(url)
          .split('/')
          .last
          .split('?')
          .first; // Assigner la valeur directement à fileName
    } else {
      fileName = idPost ??
          ""; // Utiliser l'opérateur ?? pour fournir une valeur par défaut si idPost est null
    }
// Définir la référence du fichier
    final path = reflot != null && reflot.isNotEmpty
        ? "$racine/$residence/$folderName/$reflot/$fileName"
        : "$racine/$residence/$folderName/$fileName";

    final reference = storageRef.child(path);
    print("Le chemin est : $path");
    try {
      // Supprimer le fichier
      await reference.delete();
      print('Le fichier $fileName a été supprimé avec succès.');
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        debugPrint("Fichier inexistant, aucune suppression nécessaire.");
      } else {
        debugPrint("Erreur lors de la suppression du fichier : $e");
      }
    }
  }

  Future<void> removeFileFromUrl(String url) async {
    if (url.isEmpty) {
      print('L\'URL fournie est invalide.');
      return;
    }

    try {
      // Extraire le chemin du fichier à partir de l'URL
      String decodedUrl = Uri.decodeFull(url);
      String path = decodedUrl.split('/o/').last.split('?').first;

      // Référence au fichier dans Firebase Storage
      final Reference reference = FirebaseStorage.instance.ref().child(path);

      // Supprimer le fichier
      await reference.delete();
      print('Le fichier à l\'URL $url a été supprimé avec succès.');
    } catch (e) {
      print('Erreur lors de la suppression du fichier : $e');
      // Gérer l'erreur ici
    }
  }
}
