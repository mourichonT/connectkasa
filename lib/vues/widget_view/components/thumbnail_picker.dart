import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

/// Vignettes secondaires d'une annonce (max [maxCount], en plus de l'image
/// principale gérée séparément) - chaque case remplie affiche l'image avec
/// une croix de suppression, une case "+" apparaît tant que le nombre max
/// n'est pas atteint. Upload/suppression passent par IStorageRepository
/// (même repository que l'image principale), sous
/// residences/{residence}/{folderName}/thumbnails/{uuid}.
class ThumbnailPicker extends ConsumerStatefulWidget {
  final List<String> initialThumbnails;
  final String residence;
  final String folderName;
  final int maxCount;
  final ValueChanged<List<String>> onChanged;

  const ThumbnailPicker({
    super.key,
    required this.initialThumbnails,
    required this.residence,
    required this.folderName,
    required this.onChanged,
    this.maxCount = 3,
  });

  @override
  ConsumerState<ThumbnailPicker> createState() => _ThumbnailPickerState();
}

class _ThumbnailPickerState extends ConsumerState<ThumbnailPicker> {
  late final IStorageRepository _storageServices;
  late List<String> _thumbnails;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _storageServices = ref.read(storageRepositoryProvider);
    _thumbnails = List.of(widget.initialThumbnails);
  }

  Future<String> _upload(XFile file) {
    return _storageServices
        .uploadImg(file, "residences", widget.residence,
            "${widget.folderName}/thumbnails", const Uuid().v4())
        .then((result) =>
            result.when(success: (v) => v, failure: (error) => throw error));
  }

  Future<void> _pickFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final downloadUrl = await _upload(picked);
      setState(() {
        _thumbnails = [..._thumbnails, downloadUrl];
        _uploading = false;
      });
      widget.onChanged(_thumbnails);
    } catch (e) {
      appLog("Erreur lors de l'upload d'une vignette: $e");
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Erreur lors de l'envoi de l'image : $e"),
        ),
      );
    }
  }

  // Sélection multiple en une seule fois (jusqu'aux places restantes) plutôt
  // que de rouvrir la galerie pour chaque vignette - limit n'est pas
  // garanti sur toutes les plateformes (image_picker), d'où le .take() côté
  // client en filet de sécurité.
  Future<void> _pickMultipleFromGallery() async {
    final remaining = widget.maxCount - _thumbnails.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    final newUrls = <String>[];
    Object? error;
    for (final file in picked.take(remaining)) {
      try {
        newUrls.add(await _upload(file));
      } catch (e) {
        appLog("Erreur lors de l'upload d'une vignette: $e");
        error = e;
      }
    }

    setState(() {
      _thumbnails = [..._thumbnails, ...newUrls];
      _uploading = false;
    });
    widget.onChanged(_thumbnails);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Erreur lors de l'envoi d'une image : $error"),
        ),
      );
    }
  }

  Future<void> _removeAt(int index) async {
    final url = _thumbnails[index];
    setState(() => _thumbnails = List.of(_thumbnails)..removeAt(index));
    widget.onChanged(_thumbnails);
    await _storageServices.removeFileFromUrl(url);
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(
                  'Choisir depuis la galerie (jusqu\'à ${widget.maxCount - _thumbnails.length})'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickMultipleFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const tileSize = 80.0;
    return Row(
      children: [
        for (var i = 0; i < _thumbnails.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: tileSize,
              height: tileSize,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _thumbnails[i],
                      width: tileSize,
                      height: tileSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeAt(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_thumbnails.length < widget.maxCount)
          GestureDetector(
            onTap: _uploading ? null : _showSourceSheet,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF5F6F9),
              ),
              child: _uploading
                  ? const Center(child: AppLoader())
                  : const Icon(Icons.add_photo_alternate_rounded,
                      color: Colors.black54, size: 28),
            ),
          ),
      ],
    );
  }
}
