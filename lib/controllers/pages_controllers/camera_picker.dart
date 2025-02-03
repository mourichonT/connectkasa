import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPicker extends StatefulWidget {
  const CameraPicker({super.key});

  @override
  _CameraPickerState createState() => _CameraPickerState();
}

class _CameraPickerState extends State<CameraPicker> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  late bool _isInitialized = false; // Initialiser _isInitialized à false

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.high,
    );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_controller);
  }
}
