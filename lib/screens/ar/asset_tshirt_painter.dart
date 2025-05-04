import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class AssetTshirtPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;
  final bool showTshirt;
  final ui.Image? tshirtImage;
  final double widthScale;
  final double heightScale;
  final double verticalOffset;
  final bool stabilizePosition;

  // For stabilization
  static Offset? _lastFacePosition;
  static double? _lastFaceWidth;
  static double? _lastFaceHeight;

  // Store face tracking ID to ignore camera movement
  static int? _lastFaceID;
  static Offset? _lastBodyPosition;

  // Store the last calculated tshirt position for stability
  static Offset? _lastTshirtPosition;
  static double? _lastTshirtAngle;
  static double _smoothingFactor = 0.8; // Higher value means more smoothing

  AssetTshirtPainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showTshirt,
    this.tshirtImage,
    this.widthScale = 3.0,
    this.heightScale = 1.5,
    this.verticalOffset = 0.6,
    this.stabilizePosition = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showTshirt || faces.isEmpty) return;

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

    if (tshirtImage != null) {
      _drawTshirtImage(canvas, faceToUse, tshirtImage!);
    } else {
      developer.log("T-shirt image not available, drawing placeholder");
      _drawPlaceholderTshirt(canvas, faceToUse);
    }
  }

  void _drawTshirtImage(Canvas canvas, Face face, ui.Image image) {
    // Use face dimension to estimate chest/body position
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Calculate face center
    final faceCenterX = face.boundingBox.left + (face.boundingBox.width / 2);
    final faceCenterY = face.boundingBox.top + (face.boundingBox.height / 2);
    final faceCenter =
        _scalePoint(math.Point(faceCenterX.toInt(), faceCenterY.toInt()));

    // Calculate estimated body position based on face position
    // T-shirt should be below the face
    final bodyPositionY = faceCenter.dy + (faceHeight * verticalOffset);
    final bodyPosition = Offset(faceCenter.dx, bodyPositionY);

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
    final Offset stableBodyPosition;
    final double stableFaceWidth;
    final double stableFaceHeight;

    if (stabilizePosition &&
        _lastBodyPosition != null &&
        _lastFaceWidth != null &&
        _lastFaceHeight != null) {
      // If it's phone movement, use previous positions more heavily
      final smoothFactor = isHeadMovement ? _smoothingFactor : 0.95;

      // Smooth the position to reduce jitter
      stableBodyPosition = Offset(
          _lastBodyPosition!.dx * smoothFactor +
              bodyPosition.dx * (1 - smoothFactor),
          _lastBodyPosition!.dy * smoothFactor +
              bodyPosition.dy * (1 - smoothFactor));

      // Smooth the dimensions
      stableFaceWidth =
          _lastFaceWidth! * smoothFactor + faceWidth * (1 - smoothFactor);
      stableFaceHeight =
          _lastFaceHeight! * smoothFactor + faceHeight * (1 - smoothFactor);
    } else {
      stableBodyPosition = bodyPosition;
      stableFaceWidth = faceWidth;
      stableFaceHeight = faceHeight;
    }

    // Update the last positions for next frame
    _lastBodyPosition = stableBodyPosition;
    _lastFaceWidth = stableFaceWidth;
    _lastFaceHeight = stableFaceHeight;

    // Calculate tshirt dimensions based on face width
    final tshirtWidth = stableFaceWidth * widthScale;
    final tshirtHeight = tshirtWidth * heightScale;

    // Calculate angle - using face angle for slight tilt
    double angle = 0.0;
    if (face.headEulerAngleZ != null) {
      // Convert from degrees to radians and reduce the effect for t-shirt
      angle = face.headEulerAngleZ! * math.pi / 180 * 0.3; // Reduced effect
    }

    // Apply additional stabilization to the final tshirt position
    final Offset tshirtPosition;
    final double tshirtAngle;

    if (stabilizePosition &&
        _lastTshirtPosition != null &&
        _lastTshirtAngle != null) {
      // Smooth the final position and angle for ultra stability
      tshirtPosition = Offset(
          _lastTshirtPosition!.dx * 0.8 + stableBodyPosition.dx * 0.2,
          _lastTshirtPosition!.dy * 0.8 + stableBodyPosition.dy * 0.2);
      tshirtAngle = _lastTshirtAngle! * 0.8 + angle * 0.2;
    } else {
      tshirtPosition = stableBodyPosition;
      tshirtAngle = angle;
    }

    // Update for next frame
    _lastTshirtPosition = tshirtPosition;
    _lastTshirtAngle = tshirtAngle;

    // Create destination rectangle for the image
    final destRect = Rect.fromCenter(
      center: tshirtPosition,
      width: tshirtWidth,
      height: tshirtHeight,
    );

    // Save canvas state
    canvas.save();

    // Translate and rotate canvas
    canvas.translate(tshirtPosition.dx, tshirtPosition.dy);
    canvas.rotate(tshirtAngle);
    canvas.translate(-tshirtPosition.dx, -tshirtPosition.dy);

    // Draw the image
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(image, srcRect, destRect, paint);

    // Restore canvas
    canvas.restore();
  }

  void _drawPlaceholderTshirt(Canvas canvas, Face face) {
    // Use face dimension to estimate chest/body position
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Calculate face center
    final faceCenterX = face.boundingBox.left + (face.boundingBox.width / 2);
    final faceCenterY = face.boundingBox.top + (face.boundingBox.height / 2);
    final faceCenter =
        _scalePoint(math.Point(faceCenterX.toInt(), faceCenterY.toInt()));

    // Calculate estimated body position based on face position
    final bodyPositionY = faceCenter.dy + (faceHeight * verticalOffset);
    final bodyPosition = Offset(faceCenter.dx, bodyPositionY);

    // Apply stabilization
    final Offset stableBodyPosition;
    final double stableFaceWidth;
    final double stableFaceHeight;

    if (stabilizePosition &&
        _lastBodyPosition != null &&
        _lastFaceWidth != null &&
        _lastFaceHeight != null) {
      // Smooth the position to reduce jitter
      stableBodyPosition = Offset(
          _lastBodyPosition!.dx * _smoothingFactor +
              bodyPosition.dx * (1 - _smoothingFactor),
          _lastBodyPosition!.dy * _smoothingFactor +
              bodyPosition.dy * (1 - _smoothingFactor));

      // Smooth the dimensions
      stableFaceWidth = _lastFaceWidth! * _smoothingFactor +
          faceWidth * (1 - _smoothingFactor);
      stableFaceHeight = _lastFaceHeight! * _smoothingFactor +
          faceHeight * (1 - _smoothingFactor);
    } else {
      stableBodyPosition = bodyPosition;
      stableFaceWidth = faceWidth;
      stableFaceHeight = faceHeight;
    }

    // Update the last positions for next frame
    _lastBodyPosition = stableBodyPosition;
    _lastFaceWidth = stableFaceWidth;
    _lastFaceHeight = stableFaceHeight;

    // Calculate tshirt dimensions
    final tshirtWidth = stableFaceWidth * widthScale;
    final tshirtHeight = tshirtWidth * heightScale;

    // Calculate angle
    double angle = 0.0;
    if (face.headEulerAngleZ != null) {
      angle = face.headEulerAngleZ! * math.pi / 180 * 0.3; // Reduced effect
    }

    // Save canvas state
    canvas.save();

    // Translate and rotate canvas
    canvas.translate(stableBodyPosition.dx, stableBodyPosition.dy);
    canvas.rotate(angle);

    // Draw a simple t-shirt placeholder
    final tshirtPaint = Paint()
      ..color = Colors.lightBlue.shade300
      ..style = PaintingStyle.fill;

    // Draw t-shirt body
    final bodyPath = Path();

    // T-shirt body - simplified shape
    final topWidth = tshirtWidth * 0.8;
    final neckWidth = tshirtWidth * 0.3;

    // Top of t-shirt
    bodyPath.moveTo(-topWidth / 2, -tshirtHeight * 0.3); // left shoulder
    bodyPath.lineTo(-neckWidth / 2, -tshirtHeight * 0.3); // left neck
    bodyPath.quadraticBezierTo(
        0,
        -tshirtHeight * 0.2, // neck curve
        neckWidth / 2,
        -tshirtHeight * 0.3 // right neck
        );
    bodyPath.lineTo(topWidth / 2, -tshirtHeight * 0.3); // right shoulder

    // Right sleeve and body
    bodyPath.lineTo(topWidth / 2, -tshirtHeight * 0.1); // right sleeve
    bodyPath.lineTo(tshirtWidth / 2, 0); // right body
    bodyPath.lineTo(tshirtWidth / 2, tshirtHeight / 2); // bottom right

    // Bottom
    bodyPath.lineTo(-tshirtWidth / 2, tshirtHeight / 2); // bottom left

    // Left body and sleeve
    bodyPath.lineTo(-tshirtWidth / 2, 0); // left body
    bodyPath.lineTo(-topWidth / 2, -tshirtHeight * 0.1); // left sleeve

    // Close the path
    bodyPath.close();

    canvas.drawPath(bodyPath, tshirtPaint);

    // Add some details/texture to the t-shirt
    final detailPaint = Paint()
      ..color = Colors.lightBlue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Add collar
    final collarPath = Path();
    collarPath.moveTo(-neckWidth / 2, -tshirtHeight * 0.3);
    collarPath.quadraticBezierTo(
        0, -tshirtHeight * 0.2, neckWidth / 2, -tshirtHeight * 0.3);

    canvas.drawPath(collarPath, detailPaint);

    // Add a simple design on the t-shirt
    final designPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(0, -tshirtHeight * 0.1), tshirtWidth * 0.15, designPaint);

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
  bool shouldRepaint(AssetTshirtPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.showTshirt != showTshirt ||
        oldDelegate.tshirtImage != tshirtImage ||
        oldDelegate.widthScale != widthScale ||
        oldDelegate.heightScale != heightScale ||
        oldDelegate.verticalOffset != verticalOffset ||
        oldDelegate.stabilizePosition != stabilizePosition;
  }
}
