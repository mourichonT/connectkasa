import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class CameraPicker extends StatefulWidget {
  const CameraPicker({super.key});

  @override
  State<CameraPicker> createState() => _CameraPickerState();
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
      return const Center(child: AppLoader());
    }

    return CameraPreview(_controller);
  }
}
