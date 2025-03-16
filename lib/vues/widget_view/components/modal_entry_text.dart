import 'package:flutter/material.dart';

class TextEntryModal extends StatefulWidget {
  final Function(String) onSave;

  const TextEntryModal({super.key, required this.onSave});

  @override
  _TextEntryModalState createState() => _TextEntryModalState();
}

class _TextEntryModalState extends State<TextEntryModal> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textEditingController,
              decoration: const InputDecoration(
                labelText: 'Entrez votre texte',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String text = _textEditingController.text;
                widget.onSave(text);
                Navigator.of(context).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
