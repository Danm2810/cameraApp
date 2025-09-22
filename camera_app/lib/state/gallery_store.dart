import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../services/storage_service.dart';

class GalleryStore extends ChangeNotifier {
  final List<String> _paths = [];
  List<String> get paths => List.unmodifiable(_paths);

  Future<void> loadFromDisk() async {
    final dir = await StorageService.mediaDir();
    if (!await dir.exists()) return;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _isImage(f.path))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync())); // newest first
    _paths
      ..clear()
      ..addAll(files.map((f) => f.path));
    notifyListeners();
  }

  void addPath(String path) {
    _paths.insert(0, path);
    notifyListeners();
  }

  bool _isImage(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.bmp'].contains(ext);
  }
}
