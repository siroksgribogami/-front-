import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/marketplace_colors.dart';

class MarketplaceImageAttachments {
  MarketplaceImageAttachments._();

  static const int maxCount = 20;
  static const int maxBytesPerFile = 10 * 1024 * 1024;

  static final ImagePicker picker = ImagePicker();

  static Future<List<String>> pickFromSheet(
    BuildContext context, {
    required List<String> currentPaths,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Галерея'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return [];

    final slots = maxCount - currentPaths.length;
    if (slots <= 0) {
      if (context.mounted) {
        _showLimitSnack(context, 'Можно прикрепить не больше $maxCount фото');
      }
      return [];
    }

    if (source == ImageSource.gallery) {
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (!context.mounted) return [];
      return _validatePaths(context, picked, slots);
    }

    final single = await picker.pickImage(source: source, imageQuality: 85);
    if (!context.mounted) return [];
    if (single == null) return [];
    return _validatePaths(context, [single], 1);
  }

  static Future<List<String>> _validatePaths(
    BuildContext context,
    List<XFile> files,
    int maxAdd,
  ) async {
    final out = <String>[];
    for (final file in files.take(maxAdd)) {
      if (!kIsWeb) {
        final f = File(file.path);
        if (!await f.exists()) continue;
        final len = await f.length();
        if (len > maxBytesPerFile) {
          if (context.mounted) {
            _showLimitSnack(context, 'Файл больше 10 МБ — пропущен');
          }
          continue;
        }
      }
      out.add(file.path);
    }
    return out;
  }

  static void _showLimitSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class MarketplaceAttachmentStrip extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final bool showAddTile;

  const MarketplaceAttachmentStrip({
    super.key,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
    this.showAddTile = true,
  });

  @override
  Widget build(BuildContext context) {
    final muted = MarketplaceColors.textMutedFor(context);
    if (paths.isEmpty && !showAddTile) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...paths.asMap().entries.map(
              (e) => _Thumb(path: e.value, onRemove: () => onRemove(e.key)),
            ),
            if (showAddTile && paths.length < MarketplaceImageAttachments.maxCount)
              _AddTile(onTap: onAdd),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'До ${MarketplaceImageAttachments.maxCount} изображений, до 10 МБ каждое',
          style: TextStyle(fontSize: 12, color: muted, height: 1.3),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = MarketplaceColors.textMutedFor(context).withOpacity(0.45);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5, style: BorderStyle.solid),
        ),
        child: Icon(Icons.add, color: border, size: 28),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _Thumb({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 72,
            height: 72,
            child: MarketplaceAttachmentImage(path: path),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MarketplaceAttachmentImage extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const MarketplaceAttachmentImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return FutureBuilder<List<int>>(
        future: XFile(path).readAsBytes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return ColoredBox(
              color: MarketplaceColors.surfaceFor(context),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return Image.memory(Uint8List.fromList(snap.data!), fit: fit);
        },
      );
    }
    return Image.file(File(path), fit: fit, errorBuilder: (_, __, ___) {
      return ColoredBox(
        color: MarketplaceColors.surfaceFor(context),
        child: const Icon(Icons.broken_image_outlined),
      );
    });
  }
}
