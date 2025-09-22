import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _noCameraFound = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      // Get list of available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() => _noCameraFound = true);
        return;
      }

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera setup error: $e");
      setState(() => _noCameraFound = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_noCameraFound) {
      return Scaffold(
        appBar: AppBar(title: const Text("Camera App")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "No Camera Detected",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Navigate to gallery or other parts of your app
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Navigate to gallery")),
                  );
                },
                child: const Text("Go to Gallery"),
              )
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

      return Scaffold(
      backgroundColor: const Color(0xFF343541), // GPT dark gray
      appBar: AppBar(
        backgroundColor: const Color(0xFF202123), // darker bar
        title: const Text("Camera App"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              "No Camera Detected",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // important for contrast
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: () {},
              child: const Text("Go to Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}
