import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_assets.dart';
import '../theme/app_theme.dart';

const animalAvatarNames = <String>[
  'Lion',
  'Elephant',
  'Monkey',
  'Crocodile',
  'Tiger',
  'Fox',
  'Rabbit',
  'Panda',
  'Owl',
];

class AnimalAvatar extends StatelessWidget {
  const AnimalAvatar({
    required this.name,
    this.size = 72,
    super.key,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final index = animalAvatarNames.indexOf(name);
    if (index < 0) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.lightGrey,
        child: const Icon(Icons.pets_rounded, color: AppColors.primaryDark),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<ui.Image>(
          future: _loadSpriteSheet(),
          builder: (context, snapshot) {
            final image = snapshot.data;
            if (image == null) {
              return const ColoredBox(
                color: AppColors.lightGrey,
                child: Icon(Icons.pets_rounded, color: AppColors.primaryDark),
              );
            }
            return CustomPaint(
              painter: _AnimalAvatarPainter(index, image),
            );
          },
        ),
      ),
    );
  }

  static Future<ui.Image>? _spriteSheet;

  static Future<ui.Image> _loadSpriteSheet() =>
      _spriteSheet ??= _decodeSpriteSheet();

  static Future<ui.Image> _decodeSpriteSheet() async {
    final data = await rootBundle.load(AppAssets.animals);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 1600,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

class _AnimalAvatarPainter extends CustomPainter {
  const _AnimalAvatarPainter(this.index, this.image);

  final int index;
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final columns = index < 5 ? 5 : 4;
    final rowIndex = index < 5 ? index : index - 5;
    final row = index < 5 ? 0 : 1;
    final sourceWidth = image.width / columns;
    final sourceHeight = image.height / 2;
    final sourceRect = Rect.fromLTWH(
      rowIndex * sourceWidth,
      row * sourceHeight,
      sourceWidth,
      sourceHeight,
    );
    final destinationRect = Offset.zero & size;
    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimalAvatarPainter oldDelegate) =>
      index != oldDelegate.index || !identical(image, oldDelegate.image);
}
