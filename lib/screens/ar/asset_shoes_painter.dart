import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssetShoesPainter extends CustomPainter {
  final Offset leftFootPosition;
  final Offset rightFootPosition;
  final String shoeImagePath;
  final double shoeSize;

  ui.Image? _shoeImage;
  bool _isImageLoaded = false;

  AssetShoesPainter({
    required this.leftFootPosition,
    required this.rightFootPosition,
    required this.shoeImagePath,
    required this.shoeSize,
  }) {
    _loadShoeImage();
  }

  Future<void> _loadShoeImage() async {
    try {
      final ByteData data = await rootBundle.load(shoeImagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _shoeImage = frameInfo.image;
      _isImageLoaded = true;
    } catch (e) {
      // Handle image loading error gracefully
      _isImageLoaded = false;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!_isImageLoaded || _shoeImage == null) {
      // Draw placeholder circles while image loads
      _drawPlaceholderShoes(canvas);
      return;
    }

    // Calculate shoe dimensions based on size multiplier
    final double baseShoeWidth = 120.0 * shoeSize;
    final double baseShoeHeight = 80.0 * shoeSize;

    // Draw left shoe
    _drawShoe(
      canvas,
      leftFootPosition,
      baseShoeWidth,
      baseShoeHeight,
      isLeftFoot: true,
    );

    // Draw right shoe
    _drawShoe(
      canvas,
      rightFootPosition,
      baseShoeWidth,
      baseShoeHeight,
      isLeftFoot: false,
    );
  }

  void _drawShoe(Canvas canvas, Offset position, double width, double height,
      {required bool isLeftFoot}) {
    if (_shoeImage == null) return;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Calculate shoe position (center the shoe on the foot position)
    final Rect destRect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );

    // Source rectangle (entire shoe image)
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      _shoeImage!.width.toDouble(),
      _shoeImage!.height.toDouble(),
    );

    // Save canvas state for transformations
    canvas.save();

    // For right foot, flip the shoe horizontally if needed
    if (!isLeftFoot) {
      canvas.translate(position.dx, position.dy);
      canvas.scale(-1, 1); // Flip horizontally
      canvas.translate(-position.dx, -position.dy);
    }

    // Draw the shoe with smooth scaling
    canvas.drawImageRect(_shoeImage!, srcRect, destRect, paint);

    // Restore canvas state
    canvas.restore();

    // Add subtle shadow for depth
    _drawShoeShadow(canvas, position, width, height);
  }

  void _drawShoeShadow(
      Canvas canvas, Offset position, double width, double height) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final shadowOffset = Offset(position.dx + 2, position.dy + 8);
    final shadowRect = Rect.fromCenter(
      center: shadowOffset,
      width: width * 0.8,
      height: height * 0.3,
    );

    canvas.drawOval(shadowRect, shadowPaint);
  }

  void _drawPlaceholderShoes(Canvas canvas) {
    final placeholderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw placeholder circles for shoes
    final double radius = 40.0 * shoeSize;

    // Left shoe placeholder
    canvas.drawCircle(leftFootPosition, radius, placeholderPaint);
    canvas.drawCircle(leftFootPosition, radius, outlinePaint);

    // Right shoe placeholder
    canvas.drawCircle(rightFootPosition, radius, placeholderPaint);
    canvas.drawCircle(rightFootPosition, radius, outlinePaint);

    // Draw loading indicator
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Loading...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw loading text for left shoe
    textPainter.paint(
      canvas,
      Offset(
        leftFootPosition.dx - textPainter.width / 2,
        leftFootPosition.dy - textPainter.height / 2,
      ),
    );

    // Draw loading text for right shoe
    textPainter.paint(
      canvas,
      Offset(
        rightFootPosition.dx - textPainter.width / 2,
        rightFootPosition.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant AssetShoesPainter oldDelegate) {
    return leftFootPosition != oldDelegate.leftFootPosition ||
        rightFootPosition != oldDelegate.rightFootPosition ||
        shoeSize != oldDelegate.shoeSize ||
        shoeImagePath != oldDelegate.shoeImagePath;
  }
}
