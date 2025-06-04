import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:flutter/material.dart';

class JustificatifUploader extends StatefulWidget {
  final String userUid;
  final String docId; // ID du profil_locataire

  const JustificatifUploader({
    super.key,
    required this.userUid,
    required this.docId,
  });

  @override
  State<JustificatifUploader> createState() => _JustificatifUploaderState();
}

class _JustificatifUploaderState extends State<JustificatifUploader> {
  List<Map<String, dynamic>> justificatifs = [];

  final List<String> docTypes = [
    'Justificatif de domicile',
    'Carte d’identité',
    'Avis d’imposition',
    'RIB',
    'Contrat de travail',
  ];

  void _addNewJustif() {
    setState(() {
      justificatifs.add({
        'type': null,
        'url': null,
      });
    });
  }

  void _updateJustifType(int index, String? value) {
    setState(() {
      justificatifs[index]['type'] = value;
    });
  }

  void _updateJustifUrl(int index, String url) {
    setState(() {
      justificatifs[index]['url'] = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < justificatifs.length; i++) ...[
          const SizedBox(height: 20),

          // Menu déroulant pour sélectionner le type de document
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Type de justificatif',
              border: OutlineInputBorder(),
            ),
            value: justificatifs[i]['type'],
            items: docTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => _updateJustifType(i, value),
          ),

          const SizedBox(height: 10),

          // Composant d’upload
          CameraOrFiles(
            racineFolder: 'User',
            residence: widget.userUid,
            folderName: "dossier_loc",
            title: 'Ajouter un document',
            cardOverlay: false,
            onImageUploaded: (url) => _updateJustifUrl(i, url),
          ),

          if (justificatifs[i]['url'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Document uploadé !',
                style: const TextStyle(color: Colors.green),
              ),
            ),

          const Divider(),
        ],
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _addNewJustif,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un justificatif'),
        ),
      ],
    );
  }
}
