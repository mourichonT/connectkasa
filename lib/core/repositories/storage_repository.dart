import 'dart:io';
import 'package:konodal/core/result/result.dart';
import 'package:image_picker/image_picker.dart';

/// Remplace StorageServices (Phase 2 du chantier architecture).
abstract interface class IStorageRepository {
  Future<Result<String>> uploadImg(XFile file, String racine,
      String residence, String folderName, String fileName);

  Future<Result<String>> uploadDocFile(File file, String racine,
      String residence, String folderName, String fileName, String? reflot);

  /// Duplique physiquement un fichier déjà uploadé (téléchargement des
  /// octets puis ré-upload à un nouveau chemin) - utilisé pour donner à
  /// chaque lot enfant sa propre copie du justificatif/Kbis du lot parent :
  /// un lot enfant doit rester une entité individuelle complète, y compris
  /// ses documents, même détaché plus tard (cf. project_lot_parent_child).
  Future<Result<String>> copyFile({
    required String sourceUrl,
    required String racine,
    required String residence,
    required String folderName,
    required String lotId,
    required String extension,
  });

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
