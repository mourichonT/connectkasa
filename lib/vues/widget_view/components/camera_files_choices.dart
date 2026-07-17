import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/core/utils/media_type.dart';
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
  // Opt-in : par défaut false pour ne rien changer aux usages existants
  // (documents d'identité, justificatifs, Kbis, photo de profil...) où une
  // vidéo n'a pas de sens. Seuls les posts sinistre/incivilité l'activent.
  final bool allowVideo;
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
    this.allowVideo = false,
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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool isCameraOpen = false;

  bool get _isSelectedVideo =>
      _selectedImage != null && isVideoExtension(_getFileExtension(_selectedImage!));

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
    _disposeVideoControllers();
    super.dispose();
  }

  /// Sans cette pause, disposer le contrôleur pendant une lecture en cours
  /// peut faire planter nativement le décodeur (observé sur l'émulateur
  /// Android, décodeur logiciel goldfish) - laisser MediaCodec se stabiliser
  /// avant de libérer la Surface.
  void _disposeVideoControllers() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  /// Met à jour le fichier sélectionné et, si c'est une vidéo, initialise
  /// son aperçu local (lecteur en pause sur la première frame) - sinon
  /// libère un éventuel aperçu vidéo précédent (bascule vidéo -> image).
  void _setSelectedFile(File file) {
    _disposeVideoControllers();

    setState(() {
      _selectedImage = file;
    });

    if (isVideoExtension(_getFileExtension(file))) {
      final controller = VideoPlayerController.file(file);
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _videoController = controller;
          _chewieController = ChewieController(
            videoPlayerController: controller,
            autoPlay: false,
            looping: false,
            aspectRatio: controller.value.aspectRatio,
          );
        });
      });
    }
  }

  void openCamera() async {
    setState(() {
      isCameraOpen = true;
      widget.onCameraStateChanged?.call(true);
    });

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    // L'appareil photo natif suspend Flutter le temps de la prise de vue -
    // le widget peut avoir été démonté entre-temps (navigation, retour en
    // arrière) : un setState() ici sans ce garde plantait l'app
    // ("setState() called after dispose()").
    if (!mounted) return;
    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged?.call(false);
    });

    if (pickedFile == null) return;

    _setSelectedFile(File(pickedFile.path));

    _uploadFromXFile(pickedFile);
  }

  void openVideoCamera() async {
    setState(() {
      isCameraOpen = true;
      widget.onCameraStateChanged?.call(true);
    });

    final XFile? pickedFile =
        await _picker.pickVideo(source: ImageSource.camera);

    if (!mounted) return;
    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged?.call(false);
    });

    if (pickedFile == null) return;

    _setSelectedFile(File(pickedFile.path));

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

    if (!mounted) return;
    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged?.call(false);
    });

    if (pickedFile == null || pickedFile.files.single.path == null) return;

    _setSelectedFile(File(pickedFile.files.single.path!));

    _uploadFromFilePicker(pickedFile);
  }

  /// Sélecteur galerie unifié photo/vidéo (image_picker), en un seul geste -
  /// contrairement à _pickImage (FilePicker, images/pdf uniquement, utilisé
  /// par les autres appelants de CameraOrFiles où la vidéo n'a pas de sens).
  Future<void> _pickMediaFromGallery() async {
    setState(() {
      isCameraOpen = true;
      widget.onCameraStateChanged?.call(true);
    });

    final XFile? media = await _picker.pickMedia();

    if (!mounted) return;
    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged?.call(false);
    });

    if (media == null) return;

    _setSelectedFile(File(media.path));
    _uploadFromXFile(media);
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
        _disposeVideoControllers();
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

  /// Affiche la boîte de dialogue pour choisir le média : volontairement
  /// minimal (2 choix), pas 4 - "Prendre" ouvre un tout petit choix
  /// photo/vidéo seulement si allowVideo, "Galerie" utilise le sélecteur
  /// unifié image_picker (une seule sélection, photo OU vidéo) plutôt que
  /// deux entrées séparées.
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(widget.allowVideo ? Icons.camera_alt : Icons.camera),
              title: MyTextStyle.postDesc(
                widget.allowVideo
                    ? 'Prendre une photo ou une vidéo'
                    : 'Prendre une photo',
                SizeFont.h3.size,
                Colors.black87,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (widget.allowVideo) {
                  _showCameraChoiceSheet(context);
                } else {
                  openCamera();
                }
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
                Navigator.of(sheetContext).pop();
                if (widget.allowVideo) {
                  _pickMediaFromGallery();
                } else {
                  _pickImage(ImageSource.gallery);
                }
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
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Petit choix photo/vidéo pour la capture caméra (allowVideo uniquement) -
  /// évite d'alourdir le sheet principal avec 2 entrées "Prendre" distinctes.
  void _showCameraChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _cameraChoiceButton(
                sheetContext,
                icon: Icons.camera_alt,
                label: 'Photo',
                onSelected: openCamera,
              ),
              _cameraChoiceButton(
                sheetContext,
                icon: Icons.videocam,
                label: 'Vidéo',
                onSelected: openVideoCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraChoiceButton(
    BuildContext sheetContext, {
    required IconData icon,
    required String label,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(sheetContext).pop();
        onSelected();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFF5F6F9),
            child: Icon(icon, size: 28, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          MyTextStyle.postDesc(label, SizeFont.h3.size, Colors.black87),
        ],
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
                  child: _isSelectedVideo
                      ? (_chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : const Center(child: AppLoader()))
                      : Builder(
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
              widget.allowVideo
                  ? "Ajouter une photo ou une vidéo"
                  : "Ajouter une image",
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

  // p.extension gère aussi bien '/' que '\' (chemins Windows) - un split
  // manuel sur '/' échouait sur desktop Windows et faisait passer les
  // vidéos pour des images (isVideoMedia resté à false après upload).
  String _getFileExtension(File file) {
    final ext = p.extension(file.path);
    return ext.isEmpty ? '' : ext.substring(1).toLowerCase();
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
      case 'mp4':
      case 'mov':
      case 'm4v':
        return Icons.videocam;
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
