import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AssetApparelPainter extends CustomPainter {
  final Offset torsoCenter;
  final double torsoWidth;
  final double torsoHeight;
  final String apparelImagePath;
  final double apparelSize;
  final String apparelType;
  final ui.Image? preloadedImage; // Accept pre-loaded image
  final Offset? shoulderCenter; // Add shoulder center for better positioning

  AssetApparelPainter({
    required this.torsoCenter,
    required this.torsoWidth,
    required this.torsoHeight,
    required this.apparelImagePath,
    required this.apparelSize,
    required this.apparelType,
    this.preloadedImage, // Optional pre-loaded image
    this.shoulderCenter, // Optional shoulder center
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use pre-loaded image if available, otherwise show minimal placeholder
    if (preloadedImage != null) {
      // Calculate apparel dimensions based on torso size and type
      final apparelDimensions = _calculateApparelDimensions();

      // Draw the apparel directly
      _drawApparel(
        canvas,
        apparelDimensions.width,
        apparelDimensions.height,
        apparelDimensions.offsetY,
      );
    } else {
      // Show minimal placeholder only if no image is available
      _drawMinimalPlaceholder(canvas);
    }
  }

  ApparelDimensions _calculateApparelDimensions() {
    double baseWidth = torsoWidth * apparelSize;
    double baseHeight = torsoHeight * apparelSize;
    double offsetY = 0;

    // Adjust dimensions based on apparel type
    switch (apparelType.toLowerCase()) {
      case 'shirt':
      case 'tshirt':
      case 't-shirt':
        baseWidth *= 1.3; // Wider for realistic t-shirt fit
        baseHeight *= 0.6; // Shorter height for t-shirt proportions
        offsetY =
            -torsoHeight * 0.35; // Much higher - position at neck/shoulder area
        break;

      case 'dress':
        baseWidth *= 1.1;
        baseHeight *= 1.5; // Longer coverage
        offsetY = -torsoHeight * 0.25; // Higher for dress neckline
        break;

      case 'jacket':
      case 'blazer':
        baseWidth *= 1.3; // Wider for outer wear
        baseHeight *= 0.9;
        offsetY = -torsoHeight * 0.3; // Higher for jacket collar
        break;

      case 'hoodie':
      case 'sweater':
        baseWidth *= 1.25;
        baseHeight *= 0.85;
        offsetY = -torsoHeight * 0.4; // Much higher for hood space
        break;

      default:
        baseWidth *= 1.15;
        baseHeight *= 0.8;
        offsetY = -torsoHeight * 0.3; // Default higher positioning
    }

    return ApparelDimensions(
      width: baseWidth,
      height: baseHeight,
      offsetY: offsetY,
    );
  }

  void _drawApparel(
      Canvas canvas, double width, double height, double offsetY) {
    if (preloadedImage == null) return;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Calculate apparel position based on type
    Offset apparelCenter;

    if (apparelType.toLowerCase() == 'tshirt' ||
        apparelType.toLowerCase() == 't-shirt' ||
        apparelType.toLowerCase() == 'shirt') {
      // For t-shirts, use shoulder center if available for more accurate positioning
      if (shoulderCenter != null) {
        apparelCenter = Offset(
          shoulderCenter!.dx, // Use shoulder X position
          shoulderCenter!.dy + (torsoHeight * 0.15), // Slightly below shoulders
        );
      } else {
        // Fallback to torso center with offset
        apparelCenter = Offset(
          torsoCenter.dx,
          torsoCenter.dy + offsetY,
        );
      }
    } else {
      // For other apparel types, use torso center with offset
      apparelCenter = Offset(
        torsoCenter.dx,
        torsoCenter.dy + offsetY,
      );
    }

    final Rect destRect = Rect.fromCenter(
      center: apparelCenter,
      width: width,
      height: height,
    );

    // Source rectangle (entire apparel image)
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      preloadedImage!.width.toDouble(),
      preloadedImage!.height.toDouble(),
    );

    // Draw ONLY the apparel image - no background effects
    canvas.drawImageRect(preloadedImage!, srcRect, destRect, paint);
  }

  void _drawMinimalPlaceholder(Canvas canvas) {
    // Show nothing when no image is available - completely transparent
    // This removes any rectangular background/outline
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for real-time updates
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
