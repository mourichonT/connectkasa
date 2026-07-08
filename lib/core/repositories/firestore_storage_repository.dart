import 'dart:io';
import 'package:connect_kasa/core/errors/app_exceptions.dart';
import 'package:connect_kasa/core/repositories/storage_repository.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreStorageRepository implements IStorageRepository {
  final Reference _storageRef;

  FirestoreStorageRepository({FirebaseStorage? storage})
      : _storageRef = (storage ?? FirebaseStorage.instance).ref();

  @override
  Future<Result<String>> uploadImg(XFile file, String racine,
      String residence, String folderName, String fileName) async {
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
        default:
          throw UnsupportedError(
              'Extension de fichier non prise en charge: $extension');
      }

      final reference =
          _storageRef.child("$racine/$residence/$folderName/$fileName");

      final uploadTask = reference.putFile(
        File(file.path),
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Result.success(downloadUrl);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<String>> uploadDocFile(File file, String racine,
      String residence, String folderName, String fileName, String? reflot) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();

      final mimeType = switch (extension) {
        'pdf' => 'application/pdf',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => throw UnsupportedError(
            'Extension de fichier non prise en charge: $extension'),
      };

      final path = reflot != null && reflot.isNotEmpty
          ? "$racine/$residence/$folderName/$reflot/$fileName.$extension"
          : "$racine/$residence/$folderName/$fileName.$extension";

      final reference = _storageRef.child(path);

      final uploadTask = reference.putFile(
        file,
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Result.success(downloadUrl);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeFolder(String racine, String folder) async {
    final reference = FirebaseStorage.instance.ref().child("$racine/$folder");

    try {
      await reference.delete();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeFile(
    String racine,
    String residence,
    String folderName, {
    String? reflot,
    String? url,
    String? idPost,
  }) async {
    String fileName;

    if (url != null) {
      fileName = Uri.decodeFull(url).split('/').last.split('?').first;
    } else {
      fileName = idPost ?? "";
    }

    final path = reflot != null && reflot.isNotEmpty
        ? "$racine/$residence/$folderName/$reflot/$fileName"
        : "$racine/$residence/$folderName/$fileName";

    final reference = _storageRef.child(path);
    try {
      await reference.delete();
      return const Result.success(null);
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        // Fichier déjà absent : pas une vraie erreur (cf. comportement
        // d'origine, qui ne remontait rien dans ce cas non plus).
        return const Result.success(null);
      }
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> deleteFolderRecursive(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    try {
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
      for (final prefix in result.prefixes) {
        final nested = await deleteFolderRecursive(prefix.fullPath);
        if (nested.isFailure) return nested;
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> removeFileFromUrl(String url) async {
    if (url.isEmpty) {
      return const Result.failure(
          UnknownException("L'URL fournie est invalide."));
    }

    try {
      String decodedUrl = Uri.decodeFull(url);
      String path = decodedUrl.split('/o/').last.split('?').first;

      final Reference reference = FirebaseStorage.instance.ref().child(path);

      await reference.delete();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
