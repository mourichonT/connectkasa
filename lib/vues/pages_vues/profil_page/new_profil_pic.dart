import 'dart:io';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProfilePic extends StatefulWidget {
  final String uid;
  final String imagePath;
  final Color color;
  final String refLot;
  final VoidCallback refresh;

  const ProfilePic({
    Key? key,
    required this.uid,
    required this.color,
    required this.refLot,
    required this.refresh,
    required this.imagePath,
  }) : super(key: key);

  @override
  _ProfilePicState createState() => _ProfilePicState();
}

class _ProfilePicState extends State<ProfilePic> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final StorageServices _storageServices = StorageServices();
  String fileName = const Uuid().v4();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
    });

    _storageServices.removeFile('user', widget.uid, "photo",
        url: widget.imagePath);

    _storageServices
        .uploadImg(pickedFile, 'user', widget.uid, "photo", fileName)
        .then((downloadUrl) {
      if (downloadUrl != null) {
        _updateProfilePicture(downloadUrl);
      }
    });
  }

  Future<void> _updateProfilePicture(String imageUrl) async {
    try {
      await DataBasesUserServices.updateUserField(
          uid: widget.uid, field: 'profilPic', value: imageUrl);
      widget.refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo de profil mise à jour avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    }
  }

  Future<void> _removeProfilePic() async {
    String imageUrl = "";
    _updateProfilePicture(imageUrl);

    _storageServices.removeFile('user', widget.uid, "photo",
        url: widget.imagePath);
  }

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
                _pickImage(ImageSource.camera);
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
            ListTile(
              leading: const Icon(Icons.delete),
              title: MyTextStyle.postDesc(
                'Supprimer votre photo de profil',
                SizeFont.h3.size,
                Colors.black87,
              ),
              onTap: () {
                _removeProfilePic();
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
    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          _imageFile != null
              ? ClipOval(
                  child: Image.file(
                    _imageFile!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                )
              : ProfilTile(widget.uid, 70, 65, 70, false),
          Positioned(
            right: 0,
            bottom: -10,
            child: SizedBox(
              height: 50,
              width: 50,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(80),
                    side: const BorderSide(color: Colors.white, width: 5),
                  ),
                  backgroundColor: const Color(0xFFF5F6F9),
                ),
                onPressed: () => _showImageSourceActionSheet(context),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.black45,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
