import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AssetApparelPainter extends CustomPainter {
  final Offset torsoCenter;
  final double torsoWidth;
  final double torsoHeight;
  final String apparelImagePath;
  final double apparelSize;
  final String apparelType;
  final ui.Image? preloadedImage;
  final Offset? shoulderCenter;
  final double shoulderWidth;
  final double chestWidth;

  AssetApparelPainter({
    required this.torsoCenter,
    required this.torsoWidth,
    required this.torsoHeight,
    required this.apparelImagePath,
    required this.apparelSize,
    required this.apparelType,
    this.preloadedImage,
    this.shoulderCenter,
    required this.shoulderWidth,
    required this.chestWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (preloadedImage != null) {
      _drawCleanApparel(canvas);
    } else {
      _drawSimplePlaceholder(canvas);
    }
  }

  void _drawCleanApparel(Canvas canvas) {
    // Simple, clean apparel rendering without effects
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Calculate basic dimensions
    double apparelWidth = torsoWidth * apparelSize;
    double apparelHeight = apparelWidth * 0.8; // Basic proportions

    // Simple positioning at torso center
    final Rect destRect = Rect.fromCenter(
      center: torsoCenter,
      width: apparelWidth,
      height: apparelHeight,
    );

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      preloadedImage!.width.toDouble(),
      preloadedImage!.height.toDouble(),
    );

    // Draw just the apparel image cleanly
    canvas.drawImageRect(preloadedImage!, srcRect, destRect, paint);
  }

  void _drawSimplePlaceholder(Canvas canvas) {
    // Simple placeholder without effects
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double apparelWidth = torsoWidth * apparelSize;
    double apparelHeight = apparelWidth * 0.8;

    final Rect rect = Rect.fromCenter(
      center: torsoCenter,
      width: apparelWidth,
      height: apparelHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );

    // Simple text
    final textPainter = TextPainter(
      text: TextSpan(
        text: apparelType.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        torsoCenter.dx - textPainter.width / 2,
        torsoCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ApparelDimensions {
  final double width;
  final double height;
  final double offsetY;

  ApparelDimensions({
    required this.width,
    required this.height,
    required this.offsetY,
  });
}
