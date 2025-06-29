import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class AssetHatsPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;
  final bool showHat;
  final ui.Image? hatImage;
  final double widthScale;
  final double heightScale;
  final double verticalOffset;
  final bool stabilizePosition;

  // For stabilization
  static Offset? _lastForehead;
  static Offset? _lastHeadCenter;
  static final double _smoothingFactor = 0.3; // OPTIMIZED for faster response

  static int? _lastFaceID;
  static Offset? _lastFacePosition;
  static Offset? _lastHatPosition;
  static double? _lastHatAngle;
  static double? _lastHatWidth;
  static double? _lastHatHeight;

  AssetHatsPainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showHat,
    this.hatImage,
    this.widthScale = 1.2,
    this.heightScale = 1.2,
    this.verticalOffset = -0.15,
    this.stabilizePosition = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showHat || faces.isEmpty) return;

    Face faceToUse = faces.first;
    if (_lastFaceID != null) {
      for (var face in faces) {
        if (face.trackingId == _lastFaceID) {
          faceToUse = face;
          break;
        }
      }
    }

    if (faceToUse.trackingId != null) {
      _lastFaceID = faceToUse.trackingId;
    }

    if (hatImage != null) {
      _drawHatImage(canvas, faceToUse, hatImage!);
    } else {
      _drawPlaceholderHat(canvas, faceToUse);
    }
  }

  void _drawHatImage(Canvas canvas, Face face, ui.Image image) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];

    if (leftEye == null || rightEye == null) return;

    final rawLeftEyePos = _scalePoint(leftEye.position);
    final rawRightEyePos = _scalePoint(rightEye.position);

    // Get face bounding box for precise head top detection
    final faceBox = face.boundingBox;
    final scaledFaceBox = Rect.fromLTRB(
      faceBox.left * screenSize.width / imageSize.width,
      faceBox.top * screenSize.height / imageSize.height,
      faceBox.right * screenSize.width / imageSize.width,
      faceBox.bottom * screenSize.height / imageSize.height,
    );

    // Mirror X coordinates for front camera
    final adjustedFaceBox = cameraLensDirection == CameraLensDirection.front
        ? Rect.fromLTRB(
            screenSize.width - scaledFaceBox.right,
            scaledFaceBox.top,
            screenSize.width - scaledFaceBox.left,
            scaledFaceBox.bottom,
          )
        : scaledFaceBox;

    final faceCenter = adjustedFaceBox.center;

    // Track head movement for stabilization
    bool isHeadMovement = true;
    if (_lastFacePosition != null && _lastFaceID == face.trackingId) {
      final moveDist = (_lastFacePosition! - faceCenter).distance;
      if (moveDist > 30) {
        isHeadMovement = false;
      }
    }
    _lastFacePosition = faceCenter;

    final eyeCenterX = (rawLeftEyePos.dx + rawRightEyePos.dx) / 2;
    final eyeCenterY = (rawLeftEyePos.dy + rawRightEyePos.dy) / 2;
    final eyeDistance = (rawRightEyePos.dx - rawLeftEyePos.dx).abs();

    // CRITICAL FIX: Calculate actual head top using face bounding box
    // Position hat just above forehead area to sit naturally on head
    final rawHeadTopPos = Offset(
      eyeCenterX,
      adjustedFaceBox.top -
          (eyeDistance * 0.3), // Position closer to head, just above forehead
    );

    // Fixed head width calculation based on actual face detection
    final headWidth = adjustedFaceBox.width * 0.9; // Use actual face width

    final Offset headTopPos;
    final double stableHeadWidth;

    if (stabilizePosition && _lastForehead != null && _lastHeadCenter != null) {
      final smoothFactor = isHeadMovement ? _smoothingFactor : 0.7;

      headTopPos = Offset(
          _lastForehead!.dx * smoothFactor +
              rawHeadTopPos.dx * (1 - smoothFactor),
          _lastForehead!.dy * smoothFactor +
              rawHeadTopPos.dy * (1 - smoothFactor));

      stableHeadWidth = (_lastHatWidth ?? headWidth) * smoothFactor +
          headWidth * (1 - smoothFactor);
    } else {
      headTopPos = rawHeadTopPos;
      stableHeadWidth = headWidth;
    }

    _lastForehead = headTopPos;
    _lastHeadCenter = Offset(eyeCenterX, eyeCenterY);

    // FIXED SCALING: Prevent auto-resizing, use stable dimensions
    final hatWidth = stableHeadWidth * widthScale;
    final hatHeight = hatWidth * heightScale;

    // CRITICAL FIX: Position hat naturally on top of head
    final hatCenterX = headTopPos.dx;
    final hatCenterY = headTopPos.dy +
        (hatHeight *
            verticalOffset *
            0.5); // Use hat height for consistent positioning

    // Enhanced rotation calculation for realistic head angle matching
    final angle =
        _calculateEnhancedRotationAngle(rawLeftEyePos, rawRightEyePos, face);

    final Offset hatPosition;
    final double hatAngle;
    final double finalHatWidth;
    final double finalHatHeight;

    if (stabilizePosition &&
        _lastHatPosition != null &&
        _lastHatAngle != null &&
        _lastHatWidth != null &&
        _lastHatHeight != null) {
      // OPTIMIZED: Faster response for immediate size adjustments like sunglasses
      hatPosition = Offset(_lastHatPosition!.dx * 0.4 + hatCenterX * 0.6,
          _lastHatPosition!.dy * 0.4 + hatCenterY * 0.6);
      hatAngle = _lastHatAngle! * 0.4 + angle * 0.6;
      finalHatWidth = _lastHatWidth! * 0.3 + hatWidth * 0.7;
      finalHatHeight = _lastHatHeight! * 0.3 + hatHeight * 0.7;
    } else {
      hatPosition = Offset(hatCenterX, hatCenterY);
      hatAngle = angle;
      finalHatWidth = hatWidth;
      finalHatHeight = hatHeight;
    }

    _lastHatPosition = hatPosition;
    _lastHatAngle = hatAngle;
    _lastHatWidth = finalHatWidth;
    _lastHatHeight = finalHatHeight;

    final destRect = Rect.fromCenter(
      center: hatPosition,
      width: finalHatWidth,
      height: finalHatHeight,
    );

    canvas.save();

    canvas.translate(hatPosition.dx, hatPosition.dy);
    canvas.rotate(hatAngle);
    canvas.translate(-hatPosition.dx, -hatPosition.dy);

    // Removed the black shadow background for natural appearance

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(image, srcRect, destRect, paint);

    canvas.restore();
  }

  void _drawHatShadow(Canvas canvas, Rect hatRect, double angle) {
    final shadowOffset = Offset(2, 3);
    final shadowRect = hatRect.shift(shadowOffset);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(8)),
      shadowPaint,
    );
  }

  void _drawPlaceholderHat(Canvas canvas, Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) return;

    final leftEyePos = _scalePoint(leftEye.position);
    final rightEyePos = _scalePoint(rightEye.position);

    final eyeCenterX = (leftEyePos.dx + rightEyePos.dx) / 2;
    final eyeCenterY = (leftEyePos.dy + rightEyePos.dy) / 2;
    final eyeDistance = (rightEyePos.dx - leftEyePos.dx).abs();

    final hatWidth = eyeDistance * widthScale;
    final hatHeight = hatWidth * heightScale;
    final foreheadOffset = eyeDistance * 0.6;

    final hatCenter = Offset(
      eyeCenterX,
      eyeCenterY - foreheadOffset + (hatHeight * verticalOffset),
    );

    final hatRect = Rect.fromCenter(
      center: hatCenter,
      width: hatWidth,
      height: hatHeight,
    );

    final paint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(hatRect, const Radius.circular(12)),
      paint,
    );

    final bandRect = Rect.fromCenter(
      center: Offset(hatCenter.dx, hatCenter.dy + hatHeight * 0.2),
      width: hatWidth * 0.9,
      height: hatHeight * 0.15,
    );

    final bandPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, const Radius.circular(4)),
      bandPaint,
    );
  }

  double _calculateRotationAngle(Offset leftEye, Offset rightEye) {
    final angle =
        math.atan2(rightEye.dy - leftEye.dy, rightEye.dx - leftEye.dx);
    return angle.clamp(-math.pi / 6, math.pi / 6);
  }

  // Enhanced rotation calculation using face detection data
  double _calculateEnhancedRotationAngle(
      Offset leftEye, Offset rightEye, Face face) {
    // Calculate eye-based rotation
    double eyeAngle =
        math.atan2(rightEye.dy - leftEye.dy, rightEye.dx - leftEye.dx);

    // Use face rotation if available
    if (face.headEulerAngleZ != null) {
      double faceRotation =
          face.headEulerAngleZ! * (math.pi / 180); // Convert to radians
      // Combine eye angle and face rotation for more accurate positioning
      eyeAngle = (eyeAngle + faceRotation) / 2;
    }

    // Clamp rotation for realistic range
    return eyeAngle.clamp(
        -math.pi / 4, math.pi / 4); // Allow more rotation for natural look
  }

  Offset _scalePoint(math.Point<int> point) {
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    double x = point.x.toDouble() * scaleX;
    double y = point.y.toDouble() * scaleY;

    if (cameraLensDirection == CameraLensDirection.front) {
      x = screenSize.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
