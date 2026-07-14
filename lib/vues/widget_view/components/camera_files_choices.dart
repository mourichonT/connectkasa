import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class CameraOrFiles extends ConsumerStatefulWidget {
  final String racineFolder;
  final String residence;
  final String folderName;
  final String? fileName;
  // Sous-dossier lot (refLot), pour les documents dépendant d'un lot
  // (justificatif de domicile, Kbis) - contrairement à une pièce d'identité
  // ou une photo de profil, qui restent au niveau de l'utilisateur.
  final String? lotId;
  final String title;
  final Function(bool)? onCameraStateChanged;
  final Function(String) onImageUploaded;
  final bool cardOverlay;
  // Optionnels, pas utilisés par les appelants existants (aucun changement
  // de comportement pour eux) : permettent à un formulaire de désactiver
  // sa soumission tant que l'upload est en cours, pour éviter une
  // soumission avec une image pas encore envoyée (course entre l'upload
  // asynchrone et un bouton "Ajouter"/"Enregistrer" trop rapide).
  final VoidCallback? onUploadStart;
  final VoidCallback? onUploadError;
  // Optionnel, comme onUploadStart/onUploadError ci-dessus : les documents
  // (identité, justificatif, Kbis...) ont besoin de connaître l'extension du
  // fichier pour DocumentModel.extension ; les usages "image de post"
  // (sinistre/annonce/événement) n'en ont pas besoin et n'y touchent pas.
  final Function(String)? onExtensionResolved;

  const CameraOrFiles({
    super.key,
    required this.racineFolder,
    required this.residence,
    required this.folderName,
    this.fileName,
    this.lotId,
    required this.title,
    required this.onImageUploaded,
    required this.cardOverlay,
    this.onCameraStateChanged,
    this.onUploadStart,
    this.onUploadError,
    this.onExtensionResolved,
  });

  @override
  ConsumerState<CameraOrFiles> createState() => CameraOrFilesState();
}

class CameraOrFilesState extends ConsumerState<CameraOrFiles> {
  final ImagePicker _picker = ImagePicker();
  late final IStorageRepository _storageServices;
  final String fileName = const Uuid().v4();
  File? _selectedImage;
  bool isCameraOpen = false;

  @override
  void initState() {
    super.initState();
    _storageServices = ref.read(storageRepositoryProvider);
  }

  /// Dossier Storage effectif : ajoute widget.lotId (ex: user/{uid}/
  /// justificatifDom/{refLot}/...) quand fourni, pour ranger les documents
  /// dépendant d'un lot par lot, puis widget.fileName comme sous-dossier
  /// supplémentaire quand il est fourni (ex: id du post), pour isoler
  /// les fichiers d'une même publication (residences/{residence}/annonces/{idPost}/...).
  String get _storageFolder {
    String folder = widget.folderName;
    if (widget.lotId != null && widget.lotId!.isNotEmpty) {
      folder = "$folder/${widget.lotId}";
    }
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      folder = "$folder/${widget.fileName}";
    }
    return folder;
  }

  @override
  void dispose() {
    _selectedImage = null; // Libérer la mémoire
    super.dispose();
  }

  void openCamera() async {
    setState(() {
      isCameraOpen = true;
      widget.onCameraStateChanged?.call(true);
    });

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged?.call(false);
    });

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    _uploadFromXFile(pickedFile);
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      isCameraOpen = true;
      widget.onCameraStateChanged?.call(true);
    });

    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged?.call(false);
    });

    if (pickedFile == null || pickedFile.files.single.path == null) return;

    if (mounted) {
      setState(() {
        _selectedImage = File(pickedFile.files.single.path!);
      });
    }

    _uploadFromFilePicker(pickedFile);
  }

  void _uploadFromFilePicker(FilePickerResult result) {
    final path = result.files.single.path;
    if (path != null) {
      _uploadImage(path);
    }
  }

  void _uploadFromXFile(XFile file) {
    _uploadImage(file.path);
  }

  void _uploadImage(String path) async {
    widget.onUploadStart?.call();
    final file = File(path);

    await _storageServices.removeFile(
      widget.racineFolder,
      widget.residence,
      _storageFolder,
      idPost: fileName,
    );

    try {
      final downloadUrl = await _storageServices
          .uploadImg(
            XFile(file.path),
            widget.racineFolder,
            widget.residence,
            _storageFolder,
            fileName,
          )
          .then((result) => result.when(
              success: (v) => v, failure: (error) => throw error));

      if (mounted) {
        widget.onExtensionResolved?.call(_getFileExtension(file));
        widget.onImageUploaded(downloadUrl);
      }
    } catch (e) {
      appLog("Erreur lors de l'upload de l'image: $e");
      widget.onUploadError?.call();
      // Sans ce retour visuel, un échec d'upload laisse le formulaire
      // appelant silencieusement bloqué en attente d'une image qui n'arrive
      // jamais (ex: bouton "Suivant" de step0.dart, qui ne s'affiche que
      // lorsque le chemin de l'image est renseigné).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Erreur lors de l'envoi de l'image : $e"),
          ),
        );
      }
    }
  }

  // Future<void> _pickImage(ImageSource source) async {
  //   setState(() {
  //     isCameraOpen = true;
  //   });
  //   widget.onCameraStateChanged?.call(
  //       true); // Indiquer que l'option de sélection de fichier est activée

  //   final XFile? pickedFile = await _picker.pickImage(source: source);

  //   setState(() {
  //     isCameraOpen = false;
  //   });
  //   widget.onCameraStateChanged
  //       ?.call(false); // Indiquer que la sélection est terminée

  //   if (pickedFile == null) return;

  //   if (mounted) {
  //     setState(() {
  //       _selectedImage = File(pickedFile.path);
  //     });
  //   }

  //   _uploadImage(pickedFile);
  // }

  // void _uploadImage(XFile pickedFile) {
  //   _storageServices.removeFile(
  //     widget.racineFolder,
  //     widget.residence,
  //     widget.folderName,
  //     idPost: fileName,
  //   );

  //   _storageServices
  //       .uploadImg(
  //     pickedFile,
  //     widget.racineFolder,
  //     widget.residence,
  //     widget.folderName,
  //     fileName,
  //   )
  //       .then((downloadUrl) {
  //     if (mounted && downloadUrl != null) {
  //       widget.onImageUploaded(downloadUrl);
  //     }
  //   });
  // }

  Future<void> _removeImage() async {
    try {
      if (_selectedImage != null) {
        setState(() {
          _selectedImage = null;
        });
        await _storageServices.removeFile(
          widget.racineFolder,
          widget.residence,
          _storageFolder,
          idPost: fileName,
        );
      }
    } catch (e) {
      appLog("Erreur lors de la suppression de l'image: $e");
    }
  }

  /// Affiche la boîte de dialogue pour choisir l’image
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: MyTextStyle.postDesc(
                'Prendre une photo',
                SizeFont.h3.size,
                Colors.black87,
              ),
              onTap: () {
                Navigator.of(context).pop();
                openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: MyTextStyle.postDesc(
                'Choisir depuis la galerie',
                SizeFont.h3.size,
                Colors.black87,
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: MyTextStyle.postDesc(
                  'Supprimer l\'image',
                  SizeFont.h3.size,
                  Colors.black87,
                ),
                onTap: () {
                  _removeImage();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        children: [
          _selectedImage != null
              ? SizedBox(
                  width: width,
                  height: width * 0.5,
                  child: Builder(
                    builder: (_) {
                      try {
                        return Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildErrorPlaceholder(); // custom placeholder
                          },
                        );
                      } catch (e) {
                        return _buildErrorPlaceholder();
                      }
                    },
                  ),
                )
              : _buildAddImageButton(width),
          if (_selectedImage != null)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          if (isCameraOpen)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: AppLoader(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bouton pour ajouter une image
  Widget _buildAddImageButton(double width) {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(context),
      child: Container(
        width: width,
        height: width * 0.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFF5F6F9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_rounded,
              size: 60,
              color: Colors.black54,
            ),
            const SizedBox(height: 10),
            Text(
              "Ajouter une image",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileExtension(File file) {
    final filename = file.path.split('/').last;
    return filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
  }

  IconData _getIconForExtension(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'bmp':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildErrorPlaceholder() {
    final extension =
        _selectedImage != null ? _getFileExtension(_selectedImage!) : '';
    final icon = _getIconForExtension(extension);
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('.$extension', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
