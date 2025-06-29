import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class AssetOrnamentsPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;
  final bool showOrnament;
  final ui.Image? ornamentImage;
  final double widthScale;
  final double heightScale;
  final double verticalOffset;
  final bool stabilizePosition;

  AssetOrnamentsPainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showOrnament,
    this.ornamentImage,
    this.widthScale = 2.0,
    this.heightScale = 2.5, // Updated default to match screen default
    this.verticalOffset = 0.3,
    this.stabilizePosition = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showOrnament) return;

    if (faces.isEmpty) {
      _drawFallbackOrnament(canvas, size);
      return;
    }

    Face faceToUse = faces.first;

    if (ornamentImage != null) {
      _drawSimpleOrnamentImage(canvas, faceToUse, ornamentImage!);
    } else {
      _drawSimplePlaceholderOrnament(canvas, faceToUse);
    }
  }

  void _drawFallbackOrnament(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.7;

    if (ornamentImage != null) {
      // Consistent sizing with face-based detection - independent width/height scaling
      final baseSize = size.width * 0.25;
      _drawCleanOrnament(canvas, Offset(centerX, centerY),
          baseSize * widthScale, baseSize * heightScale);
    } else {
      // Placeholder with same sizing logic
      final baseSize = size.width * 0.2;
      _drawSimplePlaceholder(canvas, Offset(centerX, centerY),
          baseSize * widthScale, baseSize * heightScale);
    }

    _drawGuidanceText(canvas, size);
  }

  void _drawGuidanceText(Canvas canvas, Size size) {
    final statusPainter = TextPainter(
      text: const TextSpan(
        text: 'Show your face to position ornament',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    statusPainter.layout();
    statusPainter.paint(
      canvas,
      Offset(
        size.width / 2 - statusPainter.width / 2,
        size.height * 0.8,
      ),
    );
  }

  void _drawSimpleOrnamentImage(Canvas canvas, Face face, ui.Image image) {
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Fixed sizing - maintain proper proportions and independent scaling
    // Base size on face width for consistency, then apply independent width/height scaling
    final baseOrnamentSize = faceWidth * 0.35; // Increased base size
    double ornamentWidth = baseOrnamentSize * widthScale;
    double ornamentHeight = baseOrnamentSize * heightScale;

    // Stable neck position - lower and more stable
    final neckPosition = _calculateStableNeckPosition(face, faceHeight);

    // Draw just the ornament cleanly
    _drawCleanOrnament(canvas, neckPosition, ornamentWidth, ornamentHeight);
  }

  Offset _calculateStableNeckPosition(Face face, double faceHeight) {
    // More stable neck positioning - ensure it stays on neck, not moving to mouth
    final double neckOffset =
        faceHeight * 0.25; // Increased offset to position lower on neck
    final double centerX = (face.boundingBox.left + face.boundingBox.right) /
        2 *
        screenSize.width /
        imageSize.width;

    final adjustedCenterX = cameraLensDirection == CameraLensDirection.front
        ? screenSize.width - centerX
        : centerX;

    // Add horizontal offset to move ornament slightly to the left for better neck positioning
    final double horizontalOffset =
        screenSize.width * 0.02; // 2% of screen width to the left
    final double finalCenterX = adjustedCenterX - horizontalOffset;

    // Position ornament well below the face bottom to ensure it's on the neck
    final double centerY =
        face.boundingBox.bottom * screenSize.height / imageSize.height +
            neckOffset;

    return Offset(finalCenterX, centerY);
  }

  void _drawCleanOrnament(
      Canvas canvas, Offset position, double width, double height) {
    if (ornamentImage == null) return;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    final Rect destRect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      ornamentImage!.width.toDouble(),
      ornamentImage!.height.toDouble(),
    );

    canvas.drawImageRect(ornamentImage!, srcRect, destRect, paint);
  }

  void _drawSimplePlaceholderOrnament(Canvas canvas, Face face) {
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Use same sizing logic as ornament image for consistency
    final baseOrnamentSize = faceWidth * 0.35;
    double ornamentWidth = baseOrnamentSize * widthScale;
    double ornamentHeight = baseOrnamentSize * heightScale;

    final neckPosition = _calculateStableNeckPosition(face, faceHeight);

    _drawSimplePlaceholder(canvas, neckPosition, ornamentWidth, ornamentHeight);
  }

  void _drawSimplePlaceholder(
      Canvas canvas, Offset position, double width, double height) {
    final paint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: position,
      width: width,
      height: height,
    );

    canvas.drawOval(rect, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ORNAMENT',
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class OrnamentDimensions {
  final double width;
  final double height;

  OrnamentDimensions({required this.width, required this.height});
}
