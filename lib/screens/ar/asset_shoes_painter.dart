import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AssetShoesPainter extends CustomPainter {
  final Offset leftFootPosition;
  final Offset rightFootPosition;
  final String shoeImagePath;
  final double shoeSize;
  final ui.Image?
      preloadedImage; // Accept preloaded image for better performance

  AssetShoesPainter({
    required this.leftFootPosition,
    required this.rightFootPosition,
    required this.shoeImagePath,
    required this.shoeSize,
    this.preloadedImage, // Optional preloaded image
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw only ONE pair of shoes
    if (preloadedImage != null) {
      _drawSinglePairShoes(canvas);
    } else {
      _drawPlaceholderPair(canvas);
    }

    // Remove debug elements for production
    // _drawDebugMarkers(canvas);
    // _drawStatus(canvas);
  }

  void _drawSinglePairShoes(Canvas canvas) {
    // Calculate shoe dimensions
    final double shoeWidth = 120.0 * shoeSize;
    final double shoeHeight = 80.0 * shoeSize;

    // Draw left shoe
    _drawShoe(canvas, leftFootPosition, shoeWidth, shoeHeight,
        isLeftFoot: true);

    // Draw right shoe
    _drawShoe(canvas, rightFootPosition, shoeWidth, shoeHeight,
        isLeftFoot: false);
  }

  void _drawPlaceholderPair(Canvas canvas) {
    // Calculate shoe dimensions
    final double shoeWidth = 120.0 * shoeSize;
    final double shoeHeight = 80.0 * shoeSize;

    // Draw left placeholder
    _drawVisibleShoe(canvas, leftFootPosition, shoeWidth, shoeHeight, true);

    // Draw right placeholder
    _drawVisibleShoe(canvas, rightFootPosition, shoeWidth, shoeHeight, false);
  }

  void _drawStatus(Canvas canvas) {
    final statusText = preloadedImage != null
        ? 'Image loaded: ${shoeImagePath.split('/').last}'
        : 'Loading image: ${shoeImagePath.split('/').last}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 120));
  }

  void _drawDebugMarkers(Canvas canvas) {
    final debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final areaPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw larger circles at foot positions for debugging
    canvas.drawCircle(leftFootPosition, 12, debugPaint);
    canvas.drawCircle(rightFootPosition, 12, debugPaint);

    // Draw detection area circles
    canvas.drawCircle(leftFootPosition, 60, areaPaint);
    canvas.drawCircle(rightFootPosition, 60, areaPaint);
  }

  void _drawShoe(Canvas canvas, Offset position, double width, double height,
      {required bool isLeftFoot}) {
    if (preloadedImage == null) return;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Calculate shoe position (center the shoe on the foot position)
    final Rect destRect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );

    // Source rectangle - crop the image to show only one shoe from the pair
    // Assume the shoe asset contains a pair side by side
    final double imageWidth = preloadedImage!.width.toDouble();
    final double imageHeight = preloadedImage!.height.toDouble();

    // For left foot, use left half of the image
    // For right foot, use right half of the image
    final Rect srcRect = isLeftFoot
        ? Rect.fromLTWH(0, 0, imageWidth / 2, imageHeight) // Left half
        : Rect.fromLTWH(
            imageWidth / 2, 0, imageWidth / 2, imageHeight); // Right half

    // Draw the shoe with smooth scaling
    canvas.drawImageRect(preloadedImage!, srcRect, destRect, paint);

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

  void _drawVisibleShoe(Canvas canvas, Offset position, double width,
      double height, bool isLeftFoot) {
    // Draw a clearly visible colored shoe shape
    final shoePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw shoe as rounded rectangle (shoe-like shape)
    final shoeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: position, width: width, height: height),
      Radius.circular(height * 0.3),
    );

    // Fill
    canvas.drawRRect(shoeRect, shoePaint);

    // Outline
    canvas.drawRRect(shoeRect, outlinePaint);

    // Add shoe details (laces area)
    final lacesPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final lacesRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(position.dx, position.dy - height * 0.1),
        width: width * 0.6,
        height: height * 0.4,
      ),
      Radius.circular(height * 0.1),
    );

    canvas.drawRRect(lacesRect, lacesPaint);

    // Add shadow
    _drawShoeShadow(canvas, position, width, height);

    // Add "L/R" text for clarity
    final textPainter = TextPainter(
      text: TextSpan(
        text: isLeftFoot ? 'L' : 'R',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
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
