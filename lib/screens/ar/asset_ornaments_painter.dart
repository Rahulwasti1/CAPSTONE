import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
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

  // For stabilization
  static Offset? _lastChinPosition;
  static double? _lastFaceWidth;
  static double? _lastFaceHeight;

  // Store face tracking ID to ignore camera movement
  static int? _lastFaceID;
  static Offset? _lastFacePosition;

  // Store the last calculated ornament position for stability
  static Offset? _lastOrnamentPosition;
  static double? _lastOrnamentAngle;
  static final double _smoothingFactor =
      0.8; // Higher value means more smoothing

  AssetOrnamentsPainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showOrnament,
    this.ornamentImage,
    this.widthScale = 2.0,
    this.heightScale = 1.2,
    this.verticalOffset = 0.3,
    this.stabilizePosition = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showOrnament) return;

    // If no faces detected, show fallback ornament for debugging
    if (faces.isEmpty) {
      _drawFallbackOrnament(canvas, size);
      return;
    }

    // Find the face with tracking ID we've seen before, or use the first one
    Face faceToUse = faces.first;
    if (_lastFaceID != null) {
      for (var face in faces) {
        if (face.trackingId == _lastFaceID) {
          faceToUse = face;
          break;
        }
      }
    }

    // Update the face tracking ID
    if (faceToUse.trackingId != null) {
      _lastFaceID = faceToUse.trackingId;
    }

    if (ornamentImage != null) {
      _drawOrnamentImage(canvas, faceToUse, ornamentImage!);
    } else {
      _drawPlaceholderOrnament(canvas, faceToUse);
    }
  }

  void _drawFallbackOrnament(Canvas canvas, Size size) {
    // Draw a visible ornament in the center-bottom area when no face is detected
    final centerX = size.width / 2;
    final centerY = size.height * 0.7; // 70% down the screen

    if (ornamentImage != null) {
      // Draw real ornament image
      final ornamentWidth = size.width * 0.2;
      final ornamentHeight = ornamentWidth;

      final srcRect = Rect.fromLTWH(0, 0, ornamentImage!.width.toDouble(),
          ornamentImage!.height.toDouble());
      final dstRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: ornamentWidth,
        height: ornamentHeight,
      );

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawImageRect(ornamentImage!, srcRect, dstRect, paint);
    } else {
      // Draw placeholder ornament
      final ornamentPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // Draw ornament as a rounded rectangle
      final ornamentRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: size.width * 0.15,
          height: size.width * 0.15,
        ),
        Radius.circular(size.width * 0.02),
      );

      canvas.drawRRect(ornamentRect, ornamentPaint);
      canvas.drawRRect(ornamentRect, outlinePaint);

      // Add text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'ORNAMENT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX - textPainter.width / 2,
          centerY - textPainter.height / 2,
        ),
      );
    }

    // Add status text
    final statusPainter = TextPainter(
      text: const TextSpan(
        text: 'Show your face to position ornament',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
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

    statusPainter.layout();
    statusPainter.paint(
      canvas,
      Offset(
        centerX - statusPainter.width / 2,
        centerY + size.width * 0.1,
      ),
    );
  }

  void _drawOrnamentImage(Canvas canvas, Face face, ui.Image image) {
    // Calculate face dimensions for sizing the ornament
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Calculate face center for movement detection
    final faceCenter = Offset(
        (face.boundingBox.left + face.boundingBox.right) / 2,
        (face.boundingBox.top + face.boundingBox.bottom) / 2);

    // Calculate ornament dimensions - make them more proportional
    double ornamentWidth, ornamentHeight;
    if (image.width == 500 && image.height == 500) {
      // Cross-black.png dimensions - smaller and more proportional
      ornamentWidth = faceWidth * 0.25;
      ornamentHeight = faceHeight * 0.25;
    } else if (image.width == 600 && image.height == 600) {
      // BKEChain.png dimensions - more proportional for necklaces
      ornamentWidth = faceWidth * 0.35;
      ornamentHeight = faceHeight * 0.3;
    } else {
      // Default sizing - conservative
      ornamentWidth = faceWidth * 0.3;
      ornamentHeight = faceHeight * 0.25;
    }

    // Apply user scaling
    ornamentWidth *= widthScale;
    ornamentHeight *= heightScale;

    // Calculate position - place directly on neck area, not hanging low
    // Use chin position or face bottom for neck-level placement
    final double neckOffset =
        faceHeight * 0.05; // Much smaller offset for neck placement
    final double centerX = faceCenter.dx;

    // Position at neck level (face bottom + minimal offset)
    final double centerY =
        face.boundingBox.bottom * screenSize.height / imageSize.height +
            neckOffset;

    // Validate dimensions
    if (ornamentWidth <= 0 || ornamentHeight <= 0) {
      return;
    }

    // Create rectangles for drawing
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ornamentWidth,
      height: ornamentHeight,
    );

    // Draw the ornament with high quality
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  void _drawPlaceholderOrnament(Canvas canvas, Face face) {
    // Get chin position
    final chin = face.contours[FaceContourType.face]?.points.lastOrNull;

    // In case we don't have contours, estimate chin position from bounding box
    final Offset chinPosition;
    if (chin != null) {
      chinPosition = _scalePoint(chin);
    } else {
      // Estimate position from bounding box
      final box = face.boundingBox;
      final faceBottom = box.bottom;
      final faceCenterX = box.center.dx;

      chinPosition =
          _scalePoint(math.Point(faceCenterX.toInt(), faceBottom.toInt()));
    }

    // Calculate face dimensions for sizing the ornament
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Calculate face center for movement detection
    final faceCenter = Offset(
        (face.boundingBox.left + face.boundingBox.right) / 2,
        (face.boundingBox.top + face.boundingBox.bottom) / 2);

    // Check if this is significant face movement or phone movement
    bool isHeadMovement = true;
    if (_lastFacePosition != null && _lastFaceID == face.trackingId) {
      // Calculate movement distance
      final moveDist = (_lastFacePosition! - faceCenter).distance;
      // If movement is very large and sudden, it's likely phone movement
      if (moveDist > 40) {
        isHeadMovement = false;
      }
    }
    _lastFacePosition = faceCenter;

    // Apply stabilization if enabled
    final Offset stableChinPosition;
    final double stableFaceWidth;
    final double stableFaceHeight;

    if (stabilizePosition &&
        _lastChinPosition != null &&
        _lastFaceWidth != null &&
        _lastFaceHeight != null) {
      // If it's phone movement, use previous positions more heavily
      final smoothFactor = isHeadMovement ? _smoothingFactor : 0.95;

      // Smooth the position to reduce jitter
      stableChinPosition = Offset(
          _lastChinPosition!.dx * smoothFactor +
              chinPosition.dx * (1 - smoothFactor),
          _lastChinPosition!.dy * smoothFactor +
              chinPosition.dy * (1 - smoothFactor));

      // Smooth the dimensions
      stableFaceWidth =
          _lastFaceWidth! * smoothFactor + faceWidth * (1 - smoothFactor);
      stableFaceHeight =
          _lastFaceHeight! * smoothFactor + faceHeight * (1 - smoothFactor);
    } else {
      stableChinPosition = chinPosition;
      stableFaceWidth = faceWidth;
      stableFaceHeight = faceHeight;
    }

    // Update the last positions for next frame
    _lastChinPosition = stableChinPosition;
    _lastFaceWidth = stableFaceWidth;
    _lastFaceHeight = stableFaceHeight;

    // Calculate ornament position - place at neck level, not hanging low
    final neckOffset =
        stableFaceHeight * 0.08; // Minimal offset for neck placement
    final centerX = stableChinPosition.dx;
    final centerY =
        stableChinPosition.dy + neckOffset; // Place close to chin/neck

    // Calculate ornament dimensions
    final ornamentWidth = stableFaceWidth * widthScale;
    final ornamentHeight = ornamentWidth * heightScale;

    // Calculate angle based on face rotation
    double angle = 0.0;
    if (face.headEulerAngleZ != null) {
      angle = face.headEulerAngleZ! * math.pi / 180;
    }

    // Apply additional stabilization
    final Offset ornamentPosition;
    final double ornamentAngle;

    if (stabilizePosition &&
        _lastOrnamentPosition != null &&
        _lastOrnamentAngle != null) {
      ornamentPosition = Offset(_lastOrnamentPosition!.dx * 0.8 + centerX * 0.2,
          _lastOrnamentPosition!.dy * 0.8 + centerY * 0.2);
      ornamentAngle = _lastOrnamentAngle! * 0.8 + angle * 0.2;
    } else {
      ornamentPosition = Offset(centerX, centerY);
      ornamentAngle = angle;
    }

    // Update for next frame
    _lastOrnamentPosition = ornamentPosition;
    _lastOrnamentAngle = ornamentAngle;

    // Save canvas state
    canvas.save();

    // Translate and rotate canvas
    canvas.translate(ornamentPosition.dx, ornamentPosition.dy);
    canvas.rotate(ornamentAngle);

    // Draw a simple necklace placeholder
    final necklacePaint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw a chain line
    final chainPath = Path();
    chainPath.moveTo(-ornamentWidth / 2, 0);
    chainPath.lineTo(ornamentWidth / 2, 0);

    canvas.drawPath(chainPath, necklacePaint);

    // Draw a pendant in the center
    final pendantPaint = Paint()
      ..color = Colors.amber.shade600
      ..style = PaintingStyle.fill;

    // Draw a teardrop/oval pendant
    final pendantPath = Path();
    pendantPath.addOval(
      Rect.fromCenter(
        center: Offset(0, ornamentHeight / 3),
        width: ornamentWidth / 3,
        height: ornamentHeight / 2,
      ),
    );

    canvas.drawPath(pendantPath, pendantPaint);

    // Add an inner highlight to the pendant
    final highlightPaint = Paint()
      ..color = Colors.amber.shade300
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, ornamentHeight / 3.5),
        width: ornamentWidth / 5,
        height: ornamentHeight / 4,
      ),
      highlightPaint,
    );

    // Restore canvas
    canvas.restore();
  }

  Offset _scalePoint(math.Point<int> point) {
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    final double x = cameraLensDirection == CameraLensDirection.front
        ? screenSize.width - (point.x * scaleX)
        : point.x * scaleX;

    final double y = point.y * scaleY;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(AssetOrnamentsPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.showOrnament != showOrnament ||
        oldDelegate.ornamentImage != ornamentImage ||
        oldDelegate.widthScale != widthScale ||
        oldDelegate.heightScale != heightScale ||
        oldDelegate.verticalOffset != verticalOffset ||
        oldDelegate.stabilizePosition != stabilizePosition;
  }
}
