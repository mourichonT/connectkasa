import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageServices {
  final storageRef = FirebaseStorage.instance.ref();

  Future<String?> uploadFile(XFile file, String racine, String residence,
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

  Future<void> removeFile(String racine, String residence, String folderName,
      {String? url, String? idPost}) async {
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

    // Référence au fichier dans Firebase Storage
    final Reference reference = FirebaseStorage.instance
        .ref()
        .child("$racine/$residence/$folderName/$fileName");

    try {
      // Supprimer le fichier
      await reference.delete();
      print('Le fichier $fileName a été supprimé avec succès.');
    } catch (e) {
      print('Erreur lors de la suppression du fichier : $e');
      // Gérer l'erreur ici
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
