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
  final double? shoulderWidth; // Add shoulder width for precise fitting
  final double? chestWidth; // Add chest width for better body fitting

  AssetApparelPainter({
    required this.torsoCenter,
    required this.torsoWidth,
    required this.torsoHeight,
    required this.apparelImagePath,
    required this.apparelSize,
    required this.apparelType,
    this.preloadedImage, // Optional pre-loaded image
    this.shoulderCenter, // Optional shoulder center
    this.shoulderWidth, // Optional shoulder width
    this.chestWidth, // Optional chest width
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
    // Use precise measurements if available
    double baseWidth = shoulderWidth ?? torsoWidth;
    double baseHeight = torsoHeight;
    double offsetY = 0;

    // Enhanced fitting based on apparel type and body measurements
    switch (apparelType.toLowerCase()) {
      case 'shirt':
      case 'tshirt':
      case 't-shirt':
        // Use chest width for more accurate t-shirt fitting
        if (chestWidth != null) {
          baseWidth = chestWidth! * 1.1; // Slightly wider for comfortable fit
        } else {
          baseWidth = baseWidth * 1.2; // Fallback
        }
        baseHeight *= 0.65; // Perfect t-shirt proportions
        offsetY = -torsoHeight * 0.4; // Higher positioning for t-shirt neckline
        break;

      case 'dress':
        baseWidth = (chestWidth ?? baseWidth) * 1.05; // Fitted dress
        baseHeight *= 1.6; // Longer coverage for dress
        offsetY = -torsoHeight * 0.35; // Dress neckline
        break;

      case 'jacket':
      case 'blazer':
        baseWidth = (shoulderWidth ?? baseWidth) * 1.35; // Wider for outer wear
        baseHeight *= 0.95;
        offsetY = -torsoHeight * 0.35; // Jacket collar positioning
        break;

      case 'hoodie':
      case 'sweater':
        baseWidth = (chestWidth ?? baseWidth) * 1.3; // Relaxed fit
        baseHeight *= 0.9;
        offsetY = -torsoHeight * 0.45; // Higher for hood space
        break;

      default:
        baseWidth = (chestWidth ?? baseWidth) * 1.15;
        baseHeight *= 0.8;
        offsetY = -torsoHeight * 0.35;
    }

    // Apply user's size preference
    baseWidth *= apparelSize;
    baseHeight *= apparelSize;

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
