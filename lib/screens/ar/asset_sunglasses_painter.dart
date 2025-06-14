import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class AssetSunglassesPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;
  final bool showSunglasses;
  final String assetImagePath;
  final ui.Image? glassesImage;
  final double widthScale;
  final double heightScale;
  final bool stabilizePosition;

  // For stabilization
  static Offset? _lastLeftEye;
  static Offset? _lastRightEye;
  static final double _smoothingFactor =
      0.75; // Increased to reduce phone movement effects

  // Store face tracking ID to ignore camera movement
  static int? _lastFaceID;
  static Offset? _lastFacePosition;

  // Store the last calculated glasses position for perfect stability
  static Offset? _lastGlassesPosition;
  static double? _lastGlassesAngle;

  AssetSunglassesPainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showSunglasses,
    required this.assetImagePath,
    this.glassesImage,
    this.widthScale = 2.8,
    this.heightScale = 0.4,
    this.stabilizePosition = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showSunglasses || faces.isEmpty) return;

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

    if (glassesImage != null) {
      _drawGlassesImage(canvas, faceToUse, glassesImage!);
    } else {
      developer.log("Glasses image not available, drawing placeholder");
      _drawPlaceholderSunglasses(canvas, faceToUse);
    }
  }

  void _drawGlassesImage(Canvas canvas, Face face, ui.Image image) {
    // Get eye landmarks and place sunglasses
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final nose = face.landmarks[FaceLandmarkType.noseBase];

    if (leftEye == null || rightEye == null) return;

    // Get scaled positions
    final rawLeftEyePos = _scalePoint(leftEye.position);
    final rawRightEyePos = _scalePoint(rightEye.position);
    final nosePos = nose != null ? _scalePoint(nose.position) : null;

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
    final Offset leftEyePos;
    final Offset rightEyePos;

    if (stabilizePosition && _lastLeftEye != null && _lastRightEye != null) {
      // If it's phone movement, use previous positions more heavily
      final smoothFactor = isHeadMovement ? _smoothingFactor : 0.95;

      // Smooth the eye positions to reduce jitter
      leftEyePos = Offset(
          _lastLeftEye!.dx * smoothFactor +
              rawLeftEyePos.dx * (1 - smoothFactor),
          _lastLeftEye!.dy * smoothFactor +
              rawLeftEyePos.dy * (1 - smoothFactor));
      rightEyePos = Offset(
          _lastRightEye!.dx * smoothFactor +
              rawRightEyePos.dx * (1 - smoothFactor),
          _lastRightEye!.dy * smoothFactor +
              rawRightEyePos.dy * (1 - smoothFactor));
    } else {
      leftEyePos = rawLeftEyePos;
      rightEyePos = rawRightEyePos;
    }

    // Update the last eye positions for next frame
    _lastLeftEye = leftEyePos;
    _lastRightEye = rightEyePos;

    // Calculate glasses dimensions
    final eyeDistance = (rightEyePos.dx - leftEyePos.dx).abs();
    final glassesWidth = eyeDistance * widthScale;
    final glassesHeight = glassesWidth * heightScale;

    // Calculate vertical offset - position glasses at a good height aligned with eyes
    // Negative value moves glasses up, positive moves them down
    double verticalOffset;
    if (nosePos != null) {
      // Use nose position to align glasses but with a smaller value to move up
      verticalOffset =
          (nosePos.dy - (leftEyePos.dy + rightEyePos.dy) / 2) * 0.1;
    } else {
      // If no nose landmark, use a small upward offset
      verticalOffset = eyeDistance * 0.05;
    }

    // Calculate glasses center position
    final centerX = (leftEyePos.dx + rightEyePos.dx) / 2;
    final centerY = (leftEyePos.dy + rightEyePos.dy) / 2 + verticalOffset;

    // Calculate angle
    final angle = _calculateRotationAngle(leftEyePos, rightEyePos);

    // Apply additional stabilization to the final glasses position
    final Offset glassesPosition;
    final double glassesAngle;

    if (stabilizePosition &&
        _lastGlassesPosition != null &&
        _lastGlassesAngle != null) {
      // Smooth the final position and angle for ultra stability
      glassesPosition = Offset(_lastGlassesPosition!.dx * 0.8 + centerX * 0.2,
          _lastGlassesPosition!.dy * 0.8 + centerY * 0.2);
      glassesAngle = _lastGlassesAngle! * 0.8 + angle * 0.2;
    } else {
      glassesPosition = Offset(centerX, centerY);
      glassesAngle = angle;
    }

    // Update for next frame
    _lastGlassesPosition = glassesPosition;
    _lastGlassesAngle = glassesAngle;

    // Create destination rectangle for the image
    final destRect = Rect.fromCenter(
      center: glassesPosition,
      width: glassesWidth,
      height: glassesHeight,
    );

    // Save canvas state
    canvas.save();

    // Translate and rotate canvas
    canvas.translate(glassesPosition.dx, glassesPosition.dy);
    canvas.rotate(glassesAngle);
    canvas.translate(-glassesPosition.dx, -glassesPosition.dy);

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

  void _drawPlaceholderSunglasses(Canvas canvas, Face face) {
    // Get eye landmarks
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final nose = face.landmarks[FaceLandmarkType.noseBase];

    if (leftEye == null || rightEye == null) return;

    // Get scaled positions
    final rawLeftEyePos = _scalePoint(leftEye.position);
    final rawRightEyePos = _scalePoint(rightEye.position);
    final nosePos = nose != null ? _scalePoint(nose.position) : null;

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
    final Offset leftEyePos;
    final Offset rightEyePos;

    if (stabilizePosition && _lastLeftEye != null && _lastRightEye != null) {
      // If it's phone movement, use previous positions more heavily
      final smoothFactor = isHeadMovement ? _smoothingFactor : 0.95;

      // Smooth the eye positions to reduce jitter
      leftEyePos = Offset(
          _lastLeftEye!.dx * smoothFactor +
              rawLeftEyePos.dx * (1 - smoothFactor),
          _lastLeftEye!.dy * smoothFactor +
              rawLeftEyePos.dy * (1 - smoothFactor));
      rightEyePos = Offset(
          _lastRightEye!.dx * smoothFactor +
              rawRightEyePos.dx * (1 - smoothFactor),
          _lastRightEye!.dy * smoothFactor +
              rawRightEyePos.dy * (1 - smoothFactor));
    } else {
      leftEyePos = rawLeftEyePos;
      rightEyePos = rawRightEyePos;
    }

    // Update the last eye positions for next frame
    _lastLeftEye = leftEyePos;
    _lastRightEye = rightEyePos;

    // Calculate glasses dimensions
    final eyeDistance = (rightEyePos.dx - leftEyePos.dx).abs();
    final glassesWidth = eyeDistance * widthScale;
    final glassesHeight = glassesWidth * heightScale;

    // Calculate vertical offset - position glasses at a good height aligned with eyes
    // Negative value moves glasses up, positive moves them down
    double verticalOffset;
    if (nosePos != null) {
      // Use nose position to align glasses but with a smaller value to move up
      verticalOffset =
          (nosePos.dy - (leftEyePos.dy + rightEyePos.dy) / 2) * 0.1;
    } else {
      // If no nose landmark, use a small upward offset
      verticalOffset = eyeDistance * 0.05;
    }

    // Calculate glasses center position
    final centerX = (leftEyePos.dx + rightEyePos.dx) / 2;
    final centerY = (leftEyePos.dy + rightEyePos.dy) / 2 + verticalOffset;

    // Calculate angle
    final angle = _calculateRotationAngle(leftEyePos, rightEyePos);

    // Apply additional stabilization to the final glasses position
    final Offset glassesPosition;
    final double glassesAngle;

    if (stabilizePosition &&
        _lastGlassesPosition != null &&
        _lastGlassesAngle != null) {
      // Smooth the final position and angle for ultra stability
      glassesPosition = Offset(_lastGlassesPosition!.dx * 0.8 + centerX * 0.2,
          _lastGlassesPosition!.dy * 0.8 + centerY * 0.2);
      glassesAngle = _lastGlassesAngle! * 0.8 + angle * 0.2;
    } else {
      glassesPosition = Offset(centerX, centerY);
      glassesAngle = angle;
    }

    // Update for next frame
    _lastGlassesPosition = glassesPosition;
    _lastGlassesAngle = glassesAngle;

    // Save canvas state
    canvas.save();

    // Translate and rotate canvas to position glasses
    canvas.translate(glassesPosition.dx, glassesPosition.dy);
    canvas.rotate(glassesAngle);

    // Draw frame
    final frameRect = Rect.fromCenter(
      center: Offset.zero,
      width: glassesWidth,
      height: glassesHeight,
    );

    final framePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Draw frame outline
    final frameOutlinePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          frameRect, Radius.circular(glassesHeight * 0.3)));

    canvas.drawPath(frameOutlinePath, framePaint);

    // Draw lenses
    final lensDistance = eyeDistance * 0.9;
    final leftLensCenter = Offset(-lensDistance / 2, 0);
    final rightLensCenter = Offset(lensDistance / 2, 0);
    final lensWidth = eyeDistance * 0.9;
    final lensHeight = glassesHeight * 0.7;

    final leftLensRect = Rect.fromCenter(
      center: leftLensCenter,
      width: lensWidth,
      height: lensHeight,
    );

    final rightLensRect = Rect.fromCenter(
      center: rightLensCenter,
      width: lensWidth,
      height: lensHeight,
    );

    final lensPaint = Paint()
      ..color = Colors.black.withAlpha(153)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            leftLensRect, Radius.circular(lensHeight * 0.3)),
        lensPaint);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rightLensRect, Radius.circular(lensHeight * 0.3)),
        lensPaint);

    // Restore canvas
    canvas.restore();
  }

  double _calculateRotationAngle(Offset leftEye, Offset rightEye) {
    final double dy = rightEye.dy - leftEye.dy;
    final double dx = rightEye.dx - leftEye.dx;
    return dx == 0 ? 0 : math.atan(dy / dx);
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
  bool shouldRepaint(AssetSunglassesPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.showSunglasses != showSunglasses ||
        oldDelegate.assetImagePath != assetImagePath ||
        oldDelegate.glassesImage != glassesImage ||
        oldDelegate.widthScale != widthScale ||
        oldDelegate.heightScale != heightScale ||
        oldDelegate.stabilizePosition != stabilizePosition;
  }
}
