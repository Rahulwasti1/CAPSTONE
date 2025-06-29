import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class WristWatchPainter extends CustomPainter {
  final ui.Image watchImage;
  final Size screenSize;
  final bool isFrontCamera;
  final double widthScale;
  final double heightScale;
  final bool wristDetected;

  WristWatchPainter({
    required this.watchImage,
    required this.screenSize,
    required this.isFrontCamera,
    required this.widthScale,
    required this.heightScale,
    required this.wristDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!wristDetected) return;

    // Calculate intelligent watch positioning and size
    final watchDimensions = _calculateWatchDimensions();
    final watchPosition = _calculateWatchPosition();

    // Draw realistic shadow for depth perception
    _drawRealisticShadow(canvas, watchPosition, watchDimensions);

    // Draw the main watch with enhanced effects
    _drawEnhancedWatch(canvas, watchPosition, watchDimensions);

    // Add subtle highlights and reflections for realism
    _addWatchReflections(canvas, watchPosition, watchDimensions);
  }

  WatchDimensions _calculateWatchDimensions() {
    // Enhanced watch sizing based on screen proportions and user preferences
    final baseWidth = screenSize.width * 0.25; // 25% of screen width as base
    final baseHeight = baseWidth * 0.8; // Watch aspect ratio

    // Apply user scaling with intelligent limits
    final width = (baseWidth * widthScale).clamp(
      screenSize.width * 0.15, // Minimum size
      screenSize.width * 0.4, // Maximum size
    );

    final height = (baseHeight * heightScale).clamp(
      screenSize.width * 0.12, // Minimum height
      screenSize.width * 0.35, // Maximum height
    );

    return WatchDimensions(width: width, height: height);
  }

  Offset _calculateWatchPosition() {
    // Fixed position approach for stability and realism
    // Position watch on the lower right area where wrist is typically visible
    final x = isFrontCamera
        ? screenSize.width *
            0.25 // Left side when using front camera (mirrored)
        : screenSize.width * 0.75; // Right side for back camera

    final y = screenSize.height * 0.65; // 65% down the screen

    return Offset(x, y);
  }

  void _drawRealisticShadow(
      Canvas canvas, Offset position, WatchDimensions dimensions) {
    // Create realistic shadow for depth and grounding
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Shadow offset to simulate natural lighting
    final shadowOffset = Offset(4, 6);
    final shadowPosition = position + shadowOffset;

    // Draw elliptical shadow (more realistic for curved watch)
    final shadowRect = Rect.fromCenter(
      center: shadowPosition,
      width: dimensions.width * 1.1,
      height: dimensions.height * 0.6, // Flattened shadow
    );

    canvas.drawOval(shadowRect, shadowPaint);
  }

  void _drawEnhancedWatch(
      Canvas canvas, Offset position, WatchDimensions dimensions) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Define source and destination rectangles
    final srcRect = Rect.fromLTWH(
        0, 0, watchImage.width.toDouble(), watchImage.height.toDouble());

    final destRect = Rect.fromCenter(
      center: position,
      width: dimensions.width,
      height: dimensions.height,
    );

    // Draw the watch with high quality rendering
    canvas.drawImageRect(watchImage, srcRect, destRect, paint);

    // Add watch band effect for realism
    _drawWatchBand(canvas, position, dimensions);
  }

  void _drawWatchBand(
      Canvas canvas, Offset position, WatchDimensions dimensions) {
    // Draw subtle watch band extending from the main watch face
    final bandPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Upper band section
    final upperBandRect = Rect.fromCenter(
      center: Offset(position.dx, position.dy - dimensions.height * 0.6),
      width: dimensions.width * 0.3,
      height: dimensions.height * 0.4,
    );

    // Lower band section
    final lowerBandRect = Rect.fromCenter(
      center: Offset(position.dx, position.dy + dimensions.height * 0.6),
      width: dimensions.width * 0.3,
      height: dimensions.height * 0.4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          upperBandRect, Radius.circular(dimensions.width * 0.05)),
      bandPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          lowerBandRect, Radius.circular(dimensions.width * 0.05)),
      bandPaint,
    );
  }

  void _addWatchReflections(
      Canvas canvas, Offset position, WatchDimensions dimensions) {
    // Add subtle highlight to simulate screen/glass reflection
    final reflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..blendMode = BlendMode.overlay;

    // Upper left highlight (simulating light reflection on watch face)
    final highlightRect = Rect.fromCenter(
      center: Offset(
        position.dx - dimensions.width * 0.2,
        position.dy - dimensions.height * 0.2,
      ),
      width: dimensions.width * 0.4,
      height: dimensions.height * 0.3,
    );

    canvas.drawOval(highlightRect, reflectionPaint);

    // Add subtle edge highlights for metallic effect
    _addMetallicEdges(canvas, position, dimensions);
  }

  void _addMetallicEdges(
      Canvas canvas, Offset position, WatchDimensions dimensions) {
    // Add subtle metallic edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    // Draw subtle edge highlight around the watch
    final edgeRect = Rect.fromCenter(
      center: position,
      width: dimensions.width * 0.95,
      height: dimensions.height * 0.95,
    );

    canvas.drawOval(edgeRect, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for real-time updates
  }
}

class WatchDimensions {
  final double width;
  final double height;

  WatchDimensions({required this.width, required this.height});
}
