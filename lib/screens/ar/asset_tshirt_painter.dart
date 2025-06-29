import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class AssetTshirtPainter extends CustomPainter {
  final List<Face> faces;
  final List<Pose> poses;
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

  // Store the last calculated tshirt position for stability - OPTIMIZED
  static Offset? _lastTshirtPosition;
  static double? _lastTshirtAngle;
  static double? _lastTshirtWidth;
  static double? _lastTshirtHeight;
  static final double _smoothingFactor =
      0.3; // REDUCED for faster response like sunglasses

  AssetTshirtPainter({
    required this.faces,
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showTshirt,
    this.tshirtImage,
    this.widthScale = 2.2,
    this.heightScale = 1.8,
    this.verticalOffset = 0.15,
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
    // REBUILT FROM SCRATCH: Proper pose-based T-shirt positioning

    // Try pose detection first for accurate body positioning
    if (poses.isNotEmpty) {
      final pose = poses.first;

      // Get required landmarks for T-shirt positioning
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final nose =
          pose.landmarks[PoseLandmarkType.nose]; // Approximate neck position

      // Ensure we have the essential landmarks
      if (leftShoulder != null &&
          rightShoulder != null &&
          leftHip != null &&
          rightHip != null) {
        // Convert landmarks to screen coordinates
        final leftShoulderPos = _scalePoint(
            math.Point(leftShoulder.x.toInt(), leftShoulder.y.toInt()));
        final rightShoulderPos = _scalePoint(
            math.Point(rightShoulder.x.toInt(), rightShoulder.y.toInt()));
        final leftHipPos =
            _scalePoint(math.Point(leftHip.x.toInt(), leftHip.y.toInt()));
        final rightHipPos =
            _scalePoint(math.Point(rightHip.x.toInt(), rightHip.y.toInt()));

        // Calculate neck position (use nose as approximation)
        final neckPos = nose != null
            ? _scalePoint(math.Point(nose.x.toInt(), nose.y.toInt()))
            : Offset(
                (leftShoulderPos.dx + rightShoulderPos.dx) / 2,
                (leftShoulderPos.dy + rightShoulderPos.dy) / 2 -
                    40, // Approximate neck above shoulders
              );

        // STEP 1: Calculate T-shirt anchor position (upper chest area)
        final shoulderCenterX = (leftShoulderPos.dx + rightShoulderPos.dx) / 2;
        final shoulderCenterY = (leftShoulderPos.dy + rightShoulderPos.dy) / 2;

        // Position T-shirt between neck and shoulders (upper chest)
        final tshirtAnchorX = shoulderCenterX;
        final tshirtAnchorY = neckPos.dy +
            ((shoulderCenterY - neckPos.dy) *
                0.7); // 70% down from neck to shoulders

        final tshirtCenter = Offset(tshirtAnchorX, tshirtAnchorY);

        // STEP 2: Calculate realistic scaling based on body proportions
        final shoulderWidth = (rightShoulderPos.dx - leftShoulderPos.dx).abs();
        final hipWidth = (rightHipPos.dx - leftHipPos.dx).abs();
        final torsoWidth =
            math.max(shoulderWidth, hipWidth); // Use wider measurement

        // Calculate T-shirt dimensions
        final tshirtWidth = torsoWidth * widthScale;
        final torsoHeight =
            ((leftHipPos.dy + rightHipPos.dy) / 2) - shoulderCenterY;
        final tshirtHeight =
            torsoHeight * heightScale * 0.8; // Cover upper 80% of torso

        // STEP 3: Calculate rotation based on shoulder angle
        final shoulderAngle = math.atan2(
          rightShoulderPos.dy - leftShoulderPos.dy,
          rightShoulderPos.dx - leftShoulderPos.dx,
        );

        // Apply stabilization for smooth movement
        final Offset finalTshirtCenter;
        final double finalTshirtWidth;
        final double finalTshirtHeight;
        final double finalTshirtAngle;

        if (stabilizePosition && _lastTshirtPosition != null) {
          // Smooth position and dimensions
          finalTshirtCenter = Offset(
            _lastTshirtPosition!.dx * 0.7 + tshirtCenter.dx * 0.3,
            _lastTshirtPosition!.dy * 0.7 + tshirtCenter.dy * 0.3,
          );
          finalTshirtWidth =
              (_lastTshirtWidth ?? tshirtWidth) * 0.7 + tshirtWidth * 0.3;
          finalTshirtHeight =
              (_lastTshirtHeight ?? tshirtHeight) * 0.7 + tshirtHeight * 0.3;
          finalTshirtAngle =
              (_lastTshirtAngle ?? shoulderAngle) * 0.7 + shoulderAngle * 0.3;
        } else {
          finalTshirtCenter = tshirtCenter;
          finalTshirtWidth = tshirtWidth;
          finalTshirtHeight = tshirtHeight;
          finalTshirtAngle = shoulderAngle;
        }

        // Store for next frame
        _lastTshirtPosition = finalTshirtCenter;
        _lastTshirtWidth = finalTshirtWidth;
        _lastTshirtHeight = finalTshirtHeight;
        _lastTshirtAngle = finalTshirtAngle;

        // STEP 4: Draw the T-shirt above the user body
        _drawTshirtOverlay(canvas, image, finalTshirtCenter, finalTshirtWidth,
            finalTshirtHeight, finalTshirtAngle);
        return;
      }
    }

    // FALLBACK: Use face detection if pose detection fails
    _drawTshirtWithFaceDetection(canvas, face, image);
  }

  void _drawTshirtOverlay(Canvas canvas, ui.Image image, Offset center,
      double width, double height, double angle) {
    final destRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    canvas.save();

    // Apply rotation around center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);

    // Draw T-shirt with proper layering
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..blendMode =
          BlendMode.srcOver; // Ensures T-shirt appears above user body

    canvas.drawImageRect(image, srcRect, destRect, paint);
    canvas.restore();
  }

  void _drawTshirtWithFaceDetection(Canvas canvas, Face face, ui.Image image) {
    // Enhanced face-based fallback for when pose detection is unavailable
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Calculate face center
    final faceCenterX = face.boundingBox.left + (face.boundingBox.width / 2);
    final faceCenterY = face.boundingBox.top + (face.boundingBox.height / 2);
    final faceCenter =
        _scalePoint(math.Point(faceCenterX.toInt(), faceCenterY.toInt()));

    // Estimate upper chest position based on face
    final chestCenterX = faceCenter.dx;
    final chestCenterY =
        faceCenter.dy + (faceHeight * 1.2); // Below face for upper chest
    final chestCenter = Offset(chestCenterX, chestCenterY);

    // Scale based on face proportions
    final estimatedTorsoWidth = faceWidth * 2.0; // Approximate shoulder width
    final tshirtWidth = estimatedTorsoWidth * widthScale;
    final tshirtHeight = tshirtWidth * heightScale;

    // Draw T-shirt
    _drawTshirtOverlay(
        canvas, image, chestCenter, tshirtWidth, tshirtHeight, 0.0);
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
