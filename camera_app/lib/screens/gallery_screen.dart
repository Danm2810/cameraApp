import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gallery_store.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    // Load files on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryStore>().loadFromDisk();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GalleryStore>();
    final items = store.paths;

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'No media yet',
                style: TextStyle(fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final path = items[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
