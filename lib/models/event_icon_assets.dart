import 'package:flutter/services.dart';

class EventIconAssets {
  static const String _assetPrefix = 'assets/event_icons/';

  static Future<List<String>> loadPaths() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = assetManifest
        .listAssets()
        .where((path) => path.startsWith(_assetPrefix))
        .where(
          (path) =>
              path.endsWith('.png') ||
              path.endsWith('.jpg') ||
              path.endsWith('.jpeg') ||
              path.endsWith('.gif'),
        )
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return paths;
  }

  static String labelFor(String path) {
    final fileName = path.split('/').last;
    final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return withoutExtension
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
