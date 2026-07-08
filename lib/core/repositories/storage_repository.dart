import 'dart:io';
import 'package:connect_kasa/core/result/result.dart';
import 'package:image_picker/image_picker.dart';

/// Remplace StorageServices (Phase 2 du chantier architecture).
abstract interface class IStorageRepository {
  Future<Result<String>> uploadImg(XFile file, String racine,
      String residence, String folderName, String fileName);

  Future<Result<String>> uploadDocFile(File file, String racine,
      String residence, String folderName, String fileName, String? reflot);

  Future<Result<void>> removeFolder(String racine, String folder);

  Future<Result<void>> removeFile(
    String racine,
    String residence,
    String folderName, {
    String? reflot,
    String? url,
    String? idPost,
  });

  /// Supprime récursivement tous les fichiers sous un chemin donné.
  Future<Result<void>> deleteFolderRecursive(String path);

  Future<Result<void>> removeFileFromUrl(String url);
}
