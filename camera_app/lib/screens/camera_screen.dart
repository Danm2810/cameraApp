import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../state/gallery_store.dart';
import 'gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  /// Discovered cameras passed in from main.dart (may be empty on Windows without a webcam)
  final List<CameraDescription> cameras;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;

  late List<CameraDescription> _cameras;
  CameraDescription? _selected;
  String? _fatal;

  // Set this to true if you prefer a visual placeholder instead of an error screen
  final bool showMockPreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameras = widget.cameras;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (_cameras.isEmpty) {
        // No physical camera (typical on Windows desktop without a webcam)
        setState(() => _fatal = 'No camera detected on this device.');
        return;
      }

      _selected = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _initFuture = _initController(_selected!);
      setState(() {});
    } catch (e) {
      setState(() => _fatal = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _initController(CameraDescription cam) async {
    await _controller?.dispose();

    // Desktop prefers BGRA; mobile prefers YUV.
    final fmt = (Platform.isAndroid || Platform.isIOS)
        ? ImageFormatGroup.yuv420
        : ImageFormatGroup.bgra8888;

    // Conservative preset on Windows
    final preset = Platform.isWindows ? ResolutionPreset.medium : ResolutionPreset.high;

    _controller = CameraController(
      cam,
      preset,
      enableAudio: false,
      imageFormatGroup: fmt,
    );

    await _controller!.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_selected != null) {
        _initFuture = _initController(_selected!);
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  void _goToGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _selected == null) return;

    final next = _selected!.lensDirection == CameraLensDirection.back
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          )
        : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first,
          );

    _selected = next;
    _initFuture = _initController(next);
    setState(() {});
  }

  Widget _noCameraView() {
    if (showMockPreview) {
      // Optional: a visual placeholder instead of an error panel
      return Scaffold(
        appBar: AppBar(title: const Text('Camera (mock)')),
        body: Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey, Colors.black54],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('No camera detected', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
        floatingActionButton: _bottomFabRow(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    }

    // Default: friendly message + actions
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 80),
              const SizedBox(height: 16),
              const Text('No camera detected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Plug in a webcam (Windows) or run on a phone. '
                'You can still browse the gallery and other features.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _goToGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Open Gallery'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // If you plug a webcam after launch, pressing Retry will re-check the list
                      setState(() {
                        _fatal = null;
                        _cameras = widget.cameras; // could be re-fetched via a route or a callback if needed
                      });
                      _bootstrap();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry detection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomFabRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_cameras.length >= 2)
          FloatingActionButton.small(
            heroTag: 'switch',
            onPressed: _switchCamera,
            child: const Icon(Icons.cameraswitch),
          ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'capture',
          onPressed: () async {
            try {
              await _initFuture;
              if (_controller == null || !_controller!.value.isInitialized) return;
              if (_controller!.value.isTakingPicture) return;

              final xfile = await _controller!.takePicture();
              final saved = await StorageService.saveCapture(xfile);
              if (!mounted) return;

              context.read<GalleryStore>().addPath(saved.path);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to gallery')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Icon(Icons.camera),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fatal != null) {
      return _noCameraView(); // app still launches and lets user continue
    }

    if (_initFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          if (_cameras.length >= 2)
            IconButton(
              tooltip: 'Switch camera',
              icon: const Icon(Icons.cameraswitch),
              onPressed: _switchCamera,
            ),
          IconButton(
            onPressed: _goToGallery,
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Open Gallery',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Camera error: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: Text('Camera not initialized'));
          }

          return Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          );
        },
      ),
      floatingActionButton: _bottomFabRow(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
