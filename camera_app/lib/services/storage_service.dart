import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:camera/camera.dart';

class StorageService {
  // App-specific media directory: <app-docs>/media
  static Future<Directory> mediaDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'media'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Copy a captured XFile into mediaDir with a timestamped name
  static Future<File> saveCapture(XFile xfile) async {
    final dir = await mediaDir();
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final ext = p.extension(xfile.path).isEmpty ? '.jpg' : p.extension(xfile.path);
    final destPath = p.join(dir.path, 'capture_$ts$ext');
    final saved = await File(xfile.path).copy(destPath);
    return saved;
  }
}
