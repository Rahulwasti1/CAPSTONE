import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class AssetWatchesPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final CameraLensDirection cameraLensDirection;
  final bool showWatch;
  final ui.Image? watchImage;
  final double widthScale;
  final double heightScale;
  final double horizontalOffset;
  final double verticalOffset;
  final bool stabilizePosition;

  // For stabilization
  static Offset? _lastWristPosition;
  static double? _lastFaceWidth;
  static double? _lastFaceHeight;
  static Offset? _lastFaceCenterPosition; // Track face center position

  // Store face tracking ID to ignore camera movement
  static int? _lastFaceID;
  static Offset? _lastFacePosition;

  // Store the last calculated watch position for stability
  static Offset? _lastWatchPosition;
  static double? _lastWatchAngle;
  static double _smoothingFactor =
      0.4; // Lower value means less smoothing (more responsive)

  AssetWatchesPainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.cameraLensDirection,
    required this.showWatch,
    this.watchImage,
    this.widthScale = 1.2,
    this.heightScale = 1.0,
    this.horizontalOffset = 0.7, // Horizontal offset for wrist positioning
    this.verticalOffset = 2.0, // Vertical offset - distance from face
    this.stabilizePosition = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showWatch || faces.isEmpty) return;

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

    if (watchImage != null) {
      _drawWatchImage(canvas, faceToUse, watchImage!);
    } else {
      developer.log("Watch image not available, drawing placeholder");
      _drawPlaceholderWatch(canvas, faceToUse);
    }
  }

  void _drawWatchImage(Canvas canvas, Face face, ui.Image image) {
    // COMPLETELY REDESIGNED WRIST TRACKING

    // Get face dimensions for scaling
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    // Get face position to anchor watch position
    final faceCenter = Offset(
      face.boundingBox.center.dx * screenSize.width / imageSize.width,
      face.boundingBox.center.dy * screenSize.height / imageSize.height,
    );

    // Mirror x-coordinate for front camera
    final mirroredFaceCenter = cameraLensDirection == CameraLensDirection.front
        ? Offset(screenSize.width - faceCenter.dx, faceCenter.dy)
        : faceCenter;

    // DIRECT WRIST TRACKING:
    // Instead of complex calculations, position directly where user places their wrist in frame

    // Base position starting at exact vertical position user set with slider
    // This allows direct user control of watch position
    double wristY = screenSize.height * verticalOffset;

    // Get the exact X position of the watch based on wrist selection
    double wristX = screenSize.width * 0.5; // Default center position

    // Look at current face area to calculate X position
    if (face.boundingBox.width > 0) {
      if (horizontalOffset > 0) {
        // RIGHT WRIST: Position to right side of center
        wristX = screenSize.width * 0.5 +
            (horizontalOffset *
                screenSize.width *
                0.3); // Increased multiplier for more hand coverage
      } else {
        // LEFT WRIST: Position to left side of center
        wristX = screenSize.width * 0.5 +
            (horizontalOffset *
                screenSize.width *
                0.3); // Increased multiplier for more hand coverage
      }
    }

    // DIRECT RESPONSE TO MOVEMENT:
    // Create high response to wrist movement based on face tracking
    double moveX = 0;
    double moveY = 0;

    if (_lastFacePosition != null) {
      // Calculate movement amount between frames (how much the face moved)
      moveX = (mirroredFaceCenter.dx - _lastFacePosition!.dx);
      moveY = (mirroredFaceCenter.dy - _lastFacePosition!.dy) *
          0.5; // Less vertical movement

      // Apply movement directly to watch position (1:1 tracking)
      wristX += moveX;
      wristY += moveY;
    }

    // Update face position for next frame
    _lastFacePosition = mirroredFaceCenter;

    // Create wrist position with direct movement
    final wristPosition = Offset(wristX, wristY);

    // MINIMAL SMOOTHING:
    // Only smooth enough to prevent jitter but maintain very responsive movement
    final Offset stableWristPosition;

    if (_lastWristPosition != null) {
      // Adaptive smoothing - use more smoothing when image capture is likely in progress
      // This prevents "jumps" during capture
      double smoothFactor =
          0.35; // Default value for normal operation (more responsive)

      // If there's been big movement recently, increase smoothing temporarily
      if (moveX.abs() > 5 || moveY.abs() > 5) {
        smoothFactor =
            0.65; // Higher value for more stability during big movements
      }

      stableWristPosition = Offset(
          _lastWristPosition!.dx * smoothFactor + wristX * (1 - smoothFactor),
          _lastWristPosition!.dy * smoothFactor + wristY * (1 - smoothFactor));
    } else {
      stableWristPosition = wristPosition;
    }

    // Update for next frame
    _lastWristPosition = stableWristPosition;

    // WATCH SIZE: Calculate based on user preference
    final double watchSize = faceWidth * widthScale * 1.5;

    // Calculate watch dimensions
    final watchWidth = watchSize;
    final watchHeight = watchSize * heightScale;

    // WATCH ANGLE:
    // Set natural angle for wrist based on which wrist it's on
    double angle = horizontalOffset > 0 ? -0.15 : 0.15; // Natural wrist angle

    // Add small reactive angle for movement
    if (moveX != 0) {
      // Add tiny angle change based on movement speed
      angle += moveX * 0.0008;
    }

    // Create destination rectangle for the image
    final destRect = Rect.fromCenter(
      center: stableWristPosition,
      width: watchWidth,
      height: watchHeight,
    );

    // Draw the watch at the calculated position
    canvas.save();
    canvas.translate(stableWristPosition.dx, stableWristPosition.dy);
    canvas.rotate(angle);
    canvas.translate(-stableWristPosition.dx, -stableWristPosition.dy);

    // Draw the image
    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(image, srcRect, destRect, paint);
    canvas.restore();
  }

  void _drawPlaceholderWatch(Canvas canvas, Face face) {
    // Use same positioning logic as _drawWatchImage
    final faceWidth =
        face.boundingBox.width * screenSize.width / imageSize.width;
    final faceHeight =
        face.boundingBox.height * screenSize.height / imageSize.height;

    final faceCenter = Offset(
      face.boundingBox.center.dx * screenSize.width / imageSize.width,
      face.boundingBox.center.dy * screenSize.height / imageSize.height,
    );

    final mirroredFaceCenter = cameraLensDirection == CameraLensDirection.front
        ? Offset(screenSize.width - faceCenter.dx, faceCenter.dy)
        : faceCenter;

    // Direct wrist positioning at user-set vertical position
    double wristY = screenSize.height * verticalOffset;
    double wristX = screenSize.width * 0.5; // Default center position

    if (face.boundingBox.width > 0) {
      if (horizontalOffset > 0) {
        // RIGHT WRIST
        wristX = screenSize.width * 0.5 +
            (horizontalOffset *
                screenSize.width *
                0.3); // Increased multiplier for more hand coverage
      } else {
        // LEFT WRIST
        wristX = screenSize.width * 0.5 +
            (horizontalOffset *
                screenSize.width *
                0.3); // Increased multiplier for more hand coverage
      }
    }

    // Direct response to movement
    double moveX = 0;
    double moveY = 0;

    if (_lastFacePosition != null) {
      // Calculate movement
      moveX = (mirroredFaceCenter.dx - _lastFacePosition!.dx);
      moveY = (mirroredFaceCenter.dy - _lastFacePosition!.dy) * 0.5;

      // Apply movement directly
      wristX += moveX;
      wristY += moveY;
    }

    // Update for next frame
    _lastFacePosition = mirroredFaceCenter;

    // Create position with direct movement
    final wristPosition = Offset(wristX, wristY);

    // Minimal smoothing
    final Offset stableWristPosition;

    if (_lastWristPosition != null) {
      // Adaptive smoothing - use more smoothing when image capture is likely in progress
      // This prevents "jumps" during capture
      double smoothFactor =
          0.35; // Default value for normal operation (more responsive)

      // If there's been big movement recently, increase smoothing temporarily
      if (moveX.abs() > 5 || moveY.abs() > 5) {
        smoothFactor =
            0.65; // Higher value for more stability during big movements
      }

      stableWristPosition = Offset(
          _lastWristPosition!.dx * smoothFactor + wristX * (1 - smoothFactor),
          _lastWristPosition!.dy * smoothFactor + wristY * (1 - smoothFactor));
    } else {
      stableWristPosition = wristPosition;
    }

    // Update for next frame
    _lastWristPosition = stableWristPosition;

    // Calculate watch dimensions
    final watchSize = faceWidth * widthScale * 1.5;
    final watchWidth = watchSize;
    final watchHeight = watchSize * heightScale;

    // Set natural angle
    double angle = horizontalOffset > 0 ? -0.15 : 0.15;

    // Add movement angle
    if (moveX != 0) {
      angle += moveX * 0.0008;
    }

    // Draw the placeholder watch
    canvas.save();
    canvas.translate(stableWristPosition.dx, stableWristPosition.dy);
    canvas.rotate(angle);

    // Draw watch face (circle)
    final watchFacePaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final watchBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset.zero, watchWidth / 2, watchFacePaint);
    canvas.drawCircle(Offset.zero, watchWidth / 2, watchBorderPaint);

    // Draw watch band
    final bandPaint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.fill;

    // Left band
    canvas.drawRect(
      Rect.fromLTWH(
        -watchWidth / 2 - watchWidth * 0.5,
        -watchHeight * 0.15,
        watchWidth * 0.5,
        watchHeight * 0.3,
      ),
      bandPaint,
    );

    // Right band
    canvas.drawRect(
      Rect.fromLTWH(
        watchWidth / 2,
        -watchHeight * 0.15,
        watchWidth * 0.5,
        watchHeight * 0.3,
      ),
      bandPaint,
    );

    // Draw watch hands
    final handPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(Offset.zero, Offset(0, -watchHeight / 6), handPaint);
    canvas.drawLine(Offset.zero, Offset(watchWidth / 6, 0), handPaint);

    // Draw center point
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 3, centerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AssetWatchesPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.showWatch != showWatch ||
        oldDelegate.watchImage != watchImage ||
        oldDelegate.widthScale != widthScale ||
        oldDelegate.heightScale != heightScale ||
        oldDelegate.horizontalOffset != horizontalOffset ||
        oldDelegate.verticalOffset != verticalOffset ||
        oldDelegate.stabilizePosition != stabilizePosition;
  }
}
