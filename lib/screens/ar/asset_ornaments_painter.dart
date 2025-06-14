import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

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
  static double _smoothingFactor = 0.8; // Higher value means more smoothing

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
    if (!showOrnament || faces.isEmpty) return;

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
      developer.log("Ornament image not available, drawing placeholder");
      _drawPlaceholderOrnament(canvas, faceToUse);
    }
  }

  void _drawOrnamentImage(Canvas canvas, Face face, ui.Image image) {
    // Log image dimensions and details to verify we're using the right image
    developer.log("🖼️ Drawing ornament image: ${image.width}x${image.height}");
    if (image.width == 500 && image.height == 500) {
      developer.log("Image dimensions match Cross-black.png (500x500)");
    } else if (image.width == 600 && image.height == 600) {
      developer.log("Image dimensions match BKEChain.png (600x600)");
    } else {
      developer.log("Unknown image dimensions: ${image.width}x${image.height}");
    }

    // Get chin and neck position landmarks
    final chin = face.contours[FaceContourType.face]?.points
        .lastOrNull; // Use bottom point of face contour

    // In case we don't have contours, estimate chin position from bounding box
    final Offset chinPosition;
    if (chin != null) {
      chinPosition = _scalePoint(chin);
    } else {
      // Estimate position from bounding box
      final box = face.boundingBox;
      final faceBottom = box.bottom;
      final faceCenterX = box.center.dx;

      // Use the bottom-center point of the face bounding box
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

    // Make very clear log message about positions
    developer.log("Face Width: $faceWidth, Face Height: $faceHeight");
    developer.log("Chin Position: $chinPosition");
    developer.log("Face Center: $faceCenter");
    developer.log("Vertical Offset: $verticalOffset");

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

    // Calculate ornament dimensions based on face width
    final ornamentWidth = stableFaceWidth * widthScale;
    final ornamentHeight = ornamentWidth * heightScale;

    // Calculate ornament position - below the chin with enhanced vertical positioning
    final neckOffset = stableFaceHeight *
        (verticalOffset * 1.2); // Enhanced scaling for lower positions
    final centerX = stableChinPosition.dx;
    final centerY = stableChinPosition.dy + neckOffset;

    // Log exact positioning
    developer.log("Ornament position: ($centerX, $centerY)");
    developer.log("Ornament size: $ornamentWidth x $ornamentHeight");
    developer.log("Vertical offset applied: $neckOffset");

    // Additional position verification
    if (ornamentWidth <= 0 || ornamentHeight <= 0) {
      developer.log("ERROR: Invalid ornament dimensions");
      return;
    }

    // Calculate angle - we use a slight angle for the neck ornament
    // based on face rotation (if available) or head pose angles
    double angle = 0.0;
    if (face.headEulerAngleZ != null) {
      // Convert from degrees to radians with reduced rotation for lower positions
      angle = (face.headEulerAngleZ! * 0.8) *
          math.pi /
          180; // Reduced rotation effect
    }

    // Apply additional stabilization to the final ornament position
    final Offset ornamentPosition;
    final double ornamentAngle;

    if (stabilizePosition &&
        _lastOrnamentPosition != null &&
        _lastOrnamentAngle != null) {
      // Enhanced smoothing for lower positions
      final double positionSmoothFactor = verticalOffset > 1.0
          ? 0.85
          : 0.8; // More smoothing for lower positions

      // Smooth the final position and angle for ultra stability
      ornamentPosition = Offset(
          _lastOrnamentPosition!.dx * positionSmoothFactor +
              centerX * (1 - positionSmoothFactor),
          _lastOrnamentPosition!.dy * positionSmoothFactor +
              centerY * (1 - positionSmoothFactor));
      ornamentAngle = _lastOrnamentAngle! * positionSmoothFactor +
          angle * (1 - positionSmoothFactor);
    } else {
      ornamentPosition = Offset(centerX, centerY);
      ornamentAngle = angle;
    }

    // Update for next frame
    _lastOrnamentPosition = ornamentPosition;
    _lastOrnamentAngle = ornamentAngle;

    // Create destination rectangle for the image
    final destRect = Rect.fromCenter(
      center: ornamentPosition,
      width: ornamentWidth,
      height: ornamentHeight,
    );

    // Save canvas state
    canvas.save();

    // Translate and rotate canvas
    canvas.translate(ornamentPosition.dx, ornamentPosition.dy);
    canvas.rotate(ornamentAngle);
    canvas.translate(-ornamentPosition.dx, -ornamentPosition.dy);

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

    // Calculate ornament dimensions
    final ornamentWidth = stableFaceWidth * widthScale;
    final ornamentHeight = ornamentWidth * heightScale;

    // Calculate ornament position - below the chin
    final neckOffset = stableFaceHeight * verticalOffset;
    final centerX = stableChinPosition.dx;
    final centerY = stableChinPosition.dy + neckOffset;

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
