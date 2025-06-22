import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

/// ✅ IMPROVED WATCH OVERLAY PAINTER with adjustable controls
class WatchOverlayPainter extends CustomPainter {
  final ui.Image watchImage;
  final Offset wristPosition;
  final Size cameraSize;
  final Size screenSize;
  final double confidence;
  final bool isFrontCamera;

  // ✅ STEP 3: Adjustable controls
  final double scale;
  final double rotation;
  final Offset offset;

  const WatchOverlayPainter({
    required this.watchImage,
    required this.wristPosition,
    required this.cameraSize,
    required this.screenSize,
    required this.confidence,
    required this.isFrontCamera,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ STEP 2: Convert wrist position from camera coordinates to screen coordinates
    final screenPos = _convertToScreenPosition();

    // Apply user offset adjustments
    final adjustedPos = screenPos + offset;

    // ✅ Calculate watch size based on confidence, screen size, and user scale
    final baseWatchSize = screenSize.width * 0.3; // Increased base size
    final confidenceScale =
        0.7 + (confidence * 0.3); // Scale based on confidence
    final finalWatchSize = baseWatchSize * confidenceScale * scale;

    // Create watch rectangle centered on adjusted wrist position
    final watchRect = Rect.fromCenter(
      center: adjustedPos,
      width: finalWatchSize,
      height: finalWatchSize,
    );

    // Source rectangle (entire watch image)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      watchImage.width.toDouble(),
      watchImage.height.toDouble(),
    );

    // ✅ Apply rotation and high quality rendering
    canvas.save();

    // Rotate around the watch center
    if (rotation != 0.0) {
      canvas.translate(adjustedPos.dx, adjustedPos.dy);
      canvas.rotate(rotation);
      canvas.translate(-adjustedPos.dx, -adjustedPos.dy);
    }

    // Paint with high quality
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // ✅ STEP 2: Draw the watch on the wrist
    canvas.drawImageRect(watchImage, srcRect, watchRect, paint);

    canvas.restore();

    // Debug overlays removed for production
  }

  /// ✅ IMPROVED coordinate conversion from camera to screen
  Offset _convertToScreenPosition() {
    // Calculate how the camera preview is scaled and positioned on screen
    final double cameraAspectRatio = cameraSize.width / cameraSize.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (cameraAspectRatio > screenAspectRatio) {
      // Camera is wider - letterboxed (black bars top/bottom)
      scale = screenSize.width / cameraSize.width;
      final double scaledHeight = cameraSize.height * scale;
      offsetY = (screenSize.height - scaledHeight) / 2;
    } else {
      // Camera is taller - pillarboxed (black bars left/right)
      scale = screenSize.height / cameraSize.height;
      final double scaledWidth = cameraSize.width * scale;
      offsetX = (screenSize.width - scaledWidth) / 2;
    }

    // Apply scaling and offset to wrist position
    double screenX = (wristPosition.dx * scale) + offsetX;
    double screenY = (wristPosition.dy * scale) + offsetY;

    // ✅ Mirror X coordinate for front camera (selfie mode)
    if (isFrontCamera) {
      screenX = screenSize.width - screenX;
    }

    // Debug prints removed for production

    return Offset(screenX, screenY);
  }

  @override
  bool shouldRepaint(WatchOverlayPainter oldDelegate) {
    return oldDelegate.wristPosition != wristPosition ||
        oldDelegate.confidence != confidence ||
        oldDelegate.watchImage != watchImage ||
        oldDelegate.scale != scale ||
        oldDelegate.rotation != rotation ||
        oldDelegate.offset != offset;
  }
}

/// ✅ DEFAULT WATCH PAINTER - Shows watch in fixed position like sunglasses/ornaments
class DefaultWatchPainter extends CustomPainter {
  final ui.Image watchImage;
  final Size screenSize;
  final bool isFrontCamera;
  final double scale;
  final double rotation;
  final Offset offset;

  const DefaultWatchPainter({
    required this.watchImage,
    required this.screenSize,
    required this.isFrontCamera,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ Place watch in a natural wrist position on screen (like sunglasses on eyes)
    // Position it in the lower portion of the screen where users typically hold their wrist
    final double centerX = screenSize.width * 0.5;
    final double centerY = screenSize.height * 0.7; // Lower portion of screen

    final basePosition = Offset(centerX, centerY);
    final adjustedPosition = basePosition + offset;

    // ✅ Calculate watch size based on screen size and user scale
    final baseWatchSize = screenSize.width * 0.3; // Same size as other AR items
    final finalWatchSize = baseWatchSize * scale;

    // Create watch rectangle centered on position
    final watchRect = Rect.fromCenter(
      center: adjustedPosition,
      width: finalWatchSize,
      height: finalWatchSize,
    );

    // Source rectangle (entire watch image)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      watchImage.width.toDouble(),
      watchImage.height.toDouble(),
    );

    // ✅ Apply rotation and high quality rendering
    canvas.save();

    // Rotate around the watch center
    if (rotation != 0.0) {
      canvas.translate(adjustedPosition.dx, adjustedPosition.dy);
      canvas.rotate(rotation);
      canvas.translate(-adjustedPosition.dx, -adjustedPosition.dy);
    }

    // Paint with high quality
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // ✅ Draw the watch at the fixed position
    canvas.drawImageRect(watchImage, srcRect, watchRect, paint);

    canvas.restore();

    print(
        "   Position: (${adjustedPosition.dx.toInt()}, ${adjustedPosition.dy.toInt()})");
    print("   Size: ${finalWatchSize.toInt()}px");
    print("   Scale: ${scale.toStringAsFixed(2)}x");
    print("   Rotation: ${(rotation * 180 / math.pi).toStringAsFixed(1)}°");
  }

  @override
  bool shouldRepaint(DefaultWatchPainter oldDelegate) {
    return oldDelegate.watchImage != watchImage ||
        oldDelegate.scale != scale ||
        oldDelegate.rotation != rotation ||
        oldDelegate.offset != offset;
  }
}

/// ✅ SIMPLE WATCH PAINTER - Uses width/height scale like sunglasses
class SimpleWatchPainter extends CustomPainter {
  final ui.Image watchImage;
  final Size screenSize;
  final bool isFrontCamera;
  final double widthScale;
  final double heightScale;

  const SimpleWatchPainter({
    required this.watchImage,
    required this.screenSize,
    required this.isFrontCamera,
    required this.widthScale,
    required this.heightScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ Place watch in a natural wrist position on screen (like sunglasses on eyes)
    // Position it in the lower portion of the screen where users typically hold their wrist
    final double centerX = screenSize.width * 0.5;
    final double centerY = screenSize.height * 0.7; // Lower portion of screen

    final basePosition = Offset(centerX, centerY);

    // ✅ Calculate realistic watch size - much smaller and more proportional
    final baseSize =
        screenSize.width * 0.15; // Reduced from 0.4 to 0.15 for realistic size
    final finalWatchWidth = baseSize * widthScale;
    final finalWatchHeight = baseSize * heightScale;

    // Create watch rectangle centered on position
    final watchRect = Rect.fromCenter(
      center: basePosition,
      width: finalWatchWidth,
      height: finalWatchHeight,
    );

    // Source rectangle (entire watch image)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      watchImage.width.toDouble(),
      watchImage.height.toDouble(),
    );

    // Paint with high quality
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // ✅ Draw the watch at the fixed position
    canvas.drawImageRect(watchImage, srcRect, watchRect, paint);

    print(
        "   Position: (${basePosition.dx.toInt()}, ${basePosition.dy.toInt()})");
    print("   Size: ${finalWatchWidth.toInt()}x${finalWatchHeight.toInt()}px");
    print("   Width Scale: ${widthScale.toStringAsFixed(2)}x");
    print("   Height Scale: ${heightScale.toStringAsFixed(2)}x");
  }

  @override
  bool shouldRepaint(SimpleWatchPainter oldDelegate) {
    return oldDelegate.watchImage != watchImage ||
        oldDelegate.widthScale != widthScale ||
        oldDelegate.heightScale != heightScale;
  }
}

/// ✅ WRIST WATCH PAINTER - Shows watch at detected wrist position with proper coordinate conversion
class WristWatchPainter extends CustomPainter {
  final ui.Image watchImage;
  final Size screenSize;
  final bool isFrontCamera;
  final double widthScale;
  final double heightScale;
  final Offset wristPosition;
  final Size cameraSize;

  const WristWatchPainter({
    required this.watchImage,
    required this.screenSize,
    required this.isFrontCamera,
    required this.widthScale,
    required this.heightScale,
    required this.wristPosition,
    required this.cameraSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert wrist position to screen coordinates
    final adjustedWristPosition = _convertWristPosition();

    // ✅ Calculate realistic watch size - much smaller and more proportional
    final baseSize =
        screenSize.width * 0.15; // Reduced from 0.4 to 0.15 for realistic size
    final finalWatchWidth = baseSize * widthScale;
    final finalWatchHeight = baseSize * heightScale;

    // Create watch rectangle centered on wrist position
    final watchRect = Rect.fromCenter(
      center: adjustedWristPosition,
      width: finalWatchWidth,
      height: finalWatchHeight,
    );

    // Source rectangle (entire watch image)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      watchImage.width.toDouble(),
      watchImage.height.toDouble(),
    );

    // Paint with high quality
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // ✅ Draw the watch at the detected wrist position
    canvas.drawImageRect(watchImage, srcRect, watchRect, paint);

    print(
        "   Adjusted Position: (${adjustedWristPosition.dx.toInt()}, ${adjustedWristPosition.dy.toInt()})");
    print("   Size: ${finalWatchWidth.toInt()}x${finalWatchHeight.toInt()}px");
    print("   Width Scale: ${widthScale.toStringAsFixed(2)}x");
    print("   Height Scale: ${heightScale.toStringAsFixed(2)}x");
  }

  /// ✅ IMPROVED coordinate conversion from camera coordinates to screen coordinates
  Offset _convertWristPosition() {
    // Get the actual camera preview size and position on screen
    final double cameraAspectRatio = cameraSize.width / cameraSize.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;

    double scaleX, scaleY;
    double offsetX = 0;
    double offsetY = 0;

    // Camera preview fills the screen, so we need to calculate how it's scaled
    if (cameraAspectRatio > screenAspectRatio) {
      // Camera is wider - it's cropped horizontally
      scaleY = screenSize.height / cameraSize.height;
      scaleX = scaleY;
      final scaledWidth = cameraSize.width * scaleX;
      offsetX = (screenSize.width - scaledWidth) / 2;
    } else {
      // Camera is taller - it's cropped vertically
      scaleX = screenSize.width / cameraSize.width;
      scaleY = scaleX;
      final scaledHeight = cameraSize.height * scaleY;
      offsetY = (screenSize.height - scaledHeight) / 2;
    }

    // Convert wrist position from camera coordinates to screen coordinates
    double screenX = (wristPosition.dx * scaleX) + offsetX;
    double screenY = (wristPosition.dy * scaleY) + offsetY;

    // ✅ Mirror X coordinate for front camera (selfie mode)
    if (isFrontCamera) {
      screenX = screenSize.width - screenX;
    }

    // ✅ Add wrist-specific offset to position watch correctly on wrist
    // The ML Kit detects the center of the wrist, but we want the watch slightly above
    final wristOffset =
        screenSize.height * 0.02; // 2% of screen height above wrist center
    screenY -= wristOffset;

    print(
        "   Camera Size: ${cameraSize.width.toInt()}x${cameraSize.height.toInt()}");
    print(
        "   Screen Size: ${screenSize.width.toInt()}x${screenSize.height.toInt()}");
    print(
        "   Scale X: ${scaleX.toStringAsFixed(3)}, Scale Y: ${scaleY.toStringAsFixed(3)}");
    print("   Offset X: ${offsetX.toInt()}, Offset Y: ${offsetY.toInt()}");
    print(
        "   Camera Wrist: (${wristPosition.dx.toInt()}, ${wristPosition.dy.toInt()})");
    print("   Screen Wrist: (${screenX.toInt()}, ${screenY.toInt()})");
    print("   Wrist Offset Applied: ${wristOffset.toInt()}px");
    print("   Front Camera: $isFrontCamera");

    return Offset(screenX, screenY);
  }

  @override
  bool shouldRepaint(WristWatchPainter oldDelegate) {
    return oldDelegate.watchImage != watchImage ||
        oldDelegate.widthScale != widthScale ||
        oldDelegate.heightScale != heightScale ||
        oldDelegate.wristPosition != wristPosition ||
        oldDelegate.cameraSize != cameraSize;
  }
}

/// Legacy painter - kept for compatibility
class AssetWatchesPainter extends CustomPainter {
  const AssetWatchesPainter({
    required this.showWatch,
    required this.widthScale,
    required this.heightScale,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.stabilizePosition,
    required this.screenSize,
    required this.imageSize,
    required this.cameraLensDirection,
    this.watchImage,
    this.leftWristPosition,
    this.rightWristPosition,
    this.useLeftWrist = true,
    this.leftWristConfidence = 0.0,
    this.rightWristConfidence = 0.0,
  });

  final bool showWatch;
  final double widthScale;
  final double heightScale;
  final double horizontalOffset;
  final double verticalOffset;
  final bool stabilizePosition;
  final Size screenSize;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;
  final ui.Image? watchImage;
  final Offset? leftWristPosition;
  final Offset? rightWristPosition;
  final bool useLeftWrist;
  final double leftWristConfidence;
  final double rightWristConfidence;

  @override
  void paint(Canvas canvas, Size size) {
    // Legacy implementation - not used
  }

  @override
  bool shouldRepaint(AssetWatchesPainter oldDelegate) {
    return false;
  }
}
