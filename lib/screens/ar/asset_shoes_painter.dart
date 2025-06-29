import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    // CRITICAL: Draw EXACTLY ONE pair of shoes (2 shoes total - left and right)
    // Prevent any duplicates by ensuring clean canvas
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Debug: Ensure we have valid positions
    if (leftFootPosition.dx < 0 ||
        leftFootPosition.dy < 0 ||
        rightFootPosition.dx < 0 ||
        rightFootPosition.dy < 0) {
      canvas.restore();
      return; // Invalid positions, don't draw anything
    }

    if (preloadedImage != null) {
      _drawRealisticShoesPair(canvas);
    } else {
      _drawPlaceholderPair(canvas);
    }

    canvas.restore();
  }

  void _drawRealisticShoesPair(Canvas canvas) {
    // CRITICAL: Render shoe PAIR image only ONCE, centered between feet
    _drawSinglePairImage(canvas);
  }

  void _drawSinglePairImage(Canvas canvas) {
    if (preloadedImage == null) return;

    // Calculate center point between both feet
    final Offset centerPoint = Offset(
      (leftFootPosition.dx + rightFootPosition.dx) / 2,
      (leftFootPosition.dy + rightFootPosition.dy) / 2,
    );

    // Calculate distance between feet for accurate scaling
    final double feetDistance = (rightFootPosition - leftFootPosition).distance;

    // Calculate angle between feet for proper rotation
    final double feetAngle = math.atan2(
      rightFootPosition.dy - leftFootPosition.dy,
      rightFootPosition.dx - leftFootPosition.dx,
    );

    // Calculate REALISTIC dimensions based on foot spacing
    // Professional shoe fitting: shoes should match natural foot spread
    final double naturalFootSpread = feetDistance;
    final double pairWidth =
        naturalFootSpread * 1.05 * shoeSize; // Slightly wider for natural fit
    final double pairHeight = pairWidth * 0.55; // Realistic shoe proportions

    canvas.save();

    // Transform to center point with natural rotation
    canvas.translate(centerPoint.dx, centerPoint.dy);
    canvas.rotate(feetAngle);

    // Draw realistic shadow system for depth and ground contact
    _drawRealisticShadow(canvas, pairWidth, pairHeight);

    // Draw the shoe pair with professional quality
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Create the destination rectangle for natural shoe placement
    final Rect destRect = Rect.fromCenter(
      center: Offset.zero,
      width: pairWidth,
      height: pairHeight,
    );

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      preloadedImage!.width.toDouble(),
      preloadedImage!.height.toDouble(),
    );

    // Render the shoe pair with realistic blending
    canvas.drawImageRect(preloadedImage!, srcRect, destRect, paint);

    // Add professional lighting effects
    _addRealisticLighting(canvas, pairWidth, pairHeight);

    // Add subtle depth and material effects
    _addMaterialEffects(canvas, pairWidth, pairHeight);

    canvas.restore();
  }

  void _drawRealisticShadow(Canvas canvas, double width, double height) {
    // Create multi-layered shadow for realistic ground contact

    // Primary shadow (direct contact)
    final primaryShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final primaryShadowRect = Rect.fromCenter(
      center: Offset(2, 8), // Natural shadow offset
      width: width * 0.85,
      height: height * 0.25, // Flattened for ground contact
    );

    canvas.drawOval(primaryShadowRect, primaryShadowPaint);

    // Secondary shadow (ambient lighting)
    final ambientShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    final ambientShadowRect = Rect.fromCenter(
      center: Offset(1, 4),
      width: width * 0.95,
      height: height * 0.35,
    );

    canvas.drawOval(ambientShadowRect, ambientShadowPaint);
  }

  void _addRealisticLighting(Canvas canvas, double width, double height) {
    // Add highlight on top surface (simulating overhead lighting)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..blendMode = BlendMode.overlay;

    final highlightRect = Rect.fromCenter(
      center: Offset(0, -height * 0.2),
      width: width * 0.6,
      height: height * 0.3,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightRect,
        Radius.circular(height * 0.08),
      ),
      highlightPaint,
    );

    // Add subtle side reflection
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..blendMode = BlendMode.softLight;

    final reflectionRect = Rect.fromCenter(
      center: Offset(-width * 0.2, 0),
      width: width * 0.15,
      height: height * 0.7,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        reflectionRect,
        Radius.circular(width * 0.02),
      ),
      reflectionPaint,
    );
  }

  void _addMaterialEffects(Canvas canvas, double width, double height) {
    // Add subtle texture and depth to make shoes look more realistic

    // Create depth gradient
    final depthPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2.0)
      ..blendMode = BlendMode.multiply;

    final depthRect = Rect.fromCenter(
      center: Offset(0, height * 0.1),
      width: width * 0.9,
      height: height * 0.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        depthRect,
        Radius.circular(height * 0.1),
      ),
      depthPaint,
    );

    // Add subtle edge definition
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.overlay;

    final edgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      Radius.circular(height * 0.12),
    );

    canvas.drawRRect(edgeRect, edgePaint);
  }

  // Removed old individual shoe rendering methods - now using single pair rendering

  void _drawPlaceholderPair(Canvas canvas) {
    // Draw single pair placeholder centered between feet
    _drawSinglePlaceholderPair(canvas);
  }

  void _drawSinglePlaceholderPair(Canvas canvas) {
    // Calculate center point between both feet
    final Offset centerPoint = Offset(
      (leftFootPosition.dx + rightFootPosition.dx) / 2,
      (leftFootPosition.dy + rightFootPosition.dy) / 2,
    );

    // Calculate distance between feet for scaling
    final double feetDistance = (rightFootPosition - leftFootPosition).distance;
    final double pairWidth = feetDistance * 1.05 * shoeSize;
    final double pairHeight = pairWidth * 0.55;

    // Calculate angle between feet for rotation
    final double feetAngle = math.atan2(
      rightFootPosition.dy - leftFootPosition.dy,
      rightFootPosition.dx - leftFootPosition.dx,
    );

    canvas.save();
    canvas.translate(centerPoint.dx, centerPoint.dy);
    canvas.rotate(feetAngle);

    // Draw placeholder pair
    final shoePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw pair as rounded rectangle
    final pairRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset.zero, width: pairWidth, height: pairHeight),
      Radius.circular(pairHeight * 0.15),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(3, 6), width: pairWidth, height: pairHeight),
      Radius.circular(pairHeight * 0.15),
    );

    canvas.drawRRect(shadowRect, shadowPaint);
    canvas.drawRRect(pairRect, shoePaint);
    canvas.drawRRect(pairRect, outlinePaint);

    // Add text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SHOE PAIR',
        style: TextStyle(
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
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  // Removed old individual placeholder rendering method - now using single pair placeholder

  @override
  bool shouldRepaint(covariant AssetShoesPainter oldDelegate) {
    return leftFootPosition != oldDelegate.leftFootPosition ||
        rightFootPosition != oldDelegate.rightFootPosition ||
        shoeSize != oldDelegate.shoeSize ||
        shoeImagePath != oldDelegate.shoeImagePath;
  }
}
