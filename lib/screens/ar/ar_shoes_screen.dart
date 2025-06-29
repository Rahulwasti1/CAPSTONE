import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:capstone/screens/ar/asset_shoes_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:capstone/service/asset_organizer_service.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class ARShoesScreen extends StatefulWidget {
  final String productName;
  final String productImage;
  final String? productId;
  final Map<String, dynamic>? productData;

  const ARShoesScreen({
    super.key,
    required this.productName,
    required this.productImage,
    this.productId,
    this.productData,
  });

  @override
  State<ARShoesScreen> createState() => _ARShoesScreenState();
}

class _ARShoesScreenState extends State<ARShoesScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  int _selectedCameraIndex = 0; // Start with back camera (index 0)

  // Pose Detection
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  // Foot positions
  Offset? _leftFootPosition;
  Offset? _rightFootPosition;

  // Detection timing
  int _lastDetectionTime = 0;
  static const int _detectionIntervalMs = 100; // 10 FPS

  // Shoe rendering
  double _shoeSize = 1.0;
  bool _showSizeControls = false; // Toggle for size controls like sunglasses

  String _detectionStatus = 'Starting AR shoes...';
  String _effectiveImagePath = '';

  // Production-ready foot detection parameters
  static const double _minFootConfidence =
      0.25; // Optimized threshold for real-world usage
  static const int _minConsecutiveDetections =
      1; // Immediate detection for better responsiveness
  int _consecutiveDetections = 0;
  bool _feetDetected = false;

  // Fallback detection when pose fails
  bool _useSmartFallback =
      false; // Try real detection first, then fallback if needed
  Offset? _fallbackLeftFoot;
  Offset? _fallbackRightFoot;

  // Timeout mechanism for guaranteed detection
  DateTime? _lastSuccessfulDetection;
  static const int _fallbackTimeoutSeconds =
      5; // Auto-fallback after 5 seconds (more time for real detection)

  // Image loading state
  ui.Image? _preloadedShoeImage;
  bool _isImageLoading = true;

  // Position smoothing - simplified for better responsiveness
  final List<Offset> _recentLeftFootPositions = [];
  final List<Offset> _recentRightFootPositions = [];
  static const int _maxPositionHistory = 3; // Reduced for faster response

  @override
  void initState() {
    super.initState();
    // Initialize timeout mechanism
    _lastSuccessfulDetection = DateTime.now();
    // Start both camera and shoe loading in parallel for faster startup
    _initializeCamera();
    _loadShoeImageFast(); // Load shoes immediately alongside camera
  }

  /// Fast shoe loading - prioritizes local assets for instant loading
  Future<void> _loadShoeImageFast() async {
    setState(() {
      _isImageLoading = true;
      _detectionStatus = 'Loading AR shoes...';
    });

    try {
      ui.Image? loadedImage;

      // Priority 1: FAST - Load default asset immediately (instant loading)
      _effectiveImagePath = _selectBestShoeAsset();
      loadedImage = await _loadImageFromAssets(_effectiveImagePath);

      // Set the fast-loading asset immediately
      if (mounted && loadedImage != null) {
        setState(() {
          _preloadedShoeImage = loadedImage;
          _isImageLoading = false;
          _detectionStatus = '📷 Point camera at your feet and step into view';
        });
      }

      // Priority 2: Try to upgrade with better images in background (non-blocking)
      _loadBetterImageInBackground();
    } catch (e) {
      // Ultimate fallback - force load black shoe
      if (mounted) {
        setState(() {
          _effectiveImagePath = 'assets/effects/shoes/Black.png';
          _detectionStatus = '📷 Point camera at your feet and step into view';
        });
        _loadImageFromAssets(_effectiveImagePath).then((image) {
          if (mounted && image != null) {
            setState(() {
              _preloadedShoeImage = image;
              _isImageLoading = false;
            });
          }
        });
      }
    }
  }

  /// Load better quality images in background without blocking UI
  Future<void> _loadBetterImageInBackground() async {
    try {
      ui.Image? betterImage;

      // Try document storage with timeout
      try {
        final documentImagesFuture = AssetOrganizerService.getProductImages(
          category: 'Shoes',
          productId: widget.productId ?? widget.productName,
          productTitle: widget.productName,
          selectedColor: null,
        );

        final documentImages = await documentImagesFuture.timeout(
          const Duration(seconds: 2), // 2 second timeout
        );

        if (documentImages.isNotEmpty) {
          betterImage = await _loadImageFromFile(documentImages.first);
          if (betterImage != null) {
            _effectiveImagePath = documentImages.first.path;
          }
        }
      } catch (e) {
        // Continue to next option if document loading fails/times out
      }

      // Try Firebase images with timeout (only if document loading failed)
      if (betterImage == null && widget.productImage.isNotEmpty) {
        try {
          betterImage = await _tryLoadFromFirebaseImagesWithTimeout();
        } catch (e) {
          // Continue if Firebase loading fails
        }
      }

      // Update UI with better image if found
      if (mounted && betterImage != null) {
        setState(() {
          _preloadedShoeImage = betterImage;
        });
      }
    } catch (e) {
      // Silently fail background loading - user already has working shoes
    }
  }

  Future<ui.Image?> _loadImageFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image?> _loadImageFromAssets(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image?> _tryLoadFromFirebaseImages() async {
    try {
      if (widget.productImage.isEmpty) return null;

      // Handle base64 image data
      if (widget.productImage.contains('base64,')) {
        String base64Image = widget.productImage.split('base64,')[1];
        final bytes = base64Decode(base64Image);

        _effectiveImagePath = 'base64_image';
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }

      // Handle network URLs
      if (widget.productImage.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.productImage));
        if (response.statusCode == 200) {
          _effectiveImagePath = widget.productImage;
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frame = await codec.getNextFrame();
          return frame.image;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Firebase image loading with timeout to prevent UI blocking
  Future<ui.Image?> _tryLoadFromFirebaseImagesWithTimeout() async {
    try {
      if (widget.productImage.isEmpty) return null;

      // Handle base64 image data (fast - no network)
      if (widget.productImage.contains('base64,')) {
        String base64Image = widget.productImage.split('base64,')[1];
        final bytes = base64Decode(base64Image);

        _effectiveImagePath = 'base64_image';
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }

      // Handle network URLs with timeout
      if (widget.productImage.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.productImage)).timeout(
              const Duration(
                  seconds: 3), // 3 second timeout for network requests
            );

        if (response.statusCode == 200) {
          _effectiveImagePath = widget.productImage;
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frame = await codec.getNextFrame();
          return frame.image;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  String _selectBestShoeAsset() {
    final String productTitle = widget.productName.toLowerCase();

    // Available shoe assets in assets/effects/shoes/
    final Map<String, String> availableShoes = {
      'Black.png': 'assets/effects/shoes/Black.png',
      'Purple.png': 'assets/effects/shoes/Purple.png',
    };

    // Enhanced matching logic - prioritize exact matches
    if (productTitle.contains('black') ||
        productTitle.contains('dark') ||
        productTitle.contains('noir') ||
        productTitle.contains('schwarz')) {
      return availableShoes['Black.png']!;
    } else if (productTitle.contains('purple') ||
        productTitle.contains('violet') ||
        productTitle.contains('lila') ||
        productTitle.contains('magenta')) {
      return availableShoes['Purple.png']!;
    }

    // For any other product, default to Black shoes
    // This ensures we always have a valid shoe to show
    return availableShoes['Black.png']!;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Find back camera first, fallback to front camera
        int backCameraIndex = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );

        if (backCameraIndex != -1) {
          _selectedCameraIndex = backCameraIndex;
        } else {
          _selectedCameraIndex = 0; // Fallback to first available camera
        }

        await _setupCamera(_selectedCameraIndex);
      }
    } catch (e) {
      setState(() {
        _detectionStatus = 'Camera initialization failed';
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset
          .medium, // Balanced resolution for fast performance and good detection
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _detectionStatus = '📷 Point camera at your feet and step into view';
        });

        _startPoseDetection();
      }
    } catch (e) {
      setState(() {
        _detectionStatus = 'Camera setup failed';
      });
    }
  }

  void _startPoseDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastDetectionTime < _detectionIntervalMs) return;

      _lastDetectionTime = now;
      _detectPose(image);
    });
  }

  Future<void> _detectPose(CameraImage image) async {
    if (_isDetecting) return;

    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);

      if (mounted) {
        _processPoseResults(poses, image.width, image.height);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detectionStatus = 'Detection error: ${e.toString()}';
        });
      }
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameras[_selectedCameraIndex];
      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  void _processPoseResults(List<Pose> poses, int imageWidth, int imageHeight) {
    final screenSize = MediaQuery.of(context).size;

    // Check if we should enable fallback after timeout
    final now = DateTime.now();
    if (_lastSuccessfulDetection != null &&
        now.difference(_lastSuccessfulDetection!).inSeconds >
            _fallbackTimeoutSeconds) {
      _useSmartFallback = true;
    }

    // SMART FALLBACK: If no poses detected, use intelligent positioning
    if (poses.isEmpty) {
      if (_useSmartFallback) {
        setState(() {
          _leftFootPosition =
              Offset(screenSize.width * 0.35, screenSize.height * 0.75);
          _rightFootPosition =
              Offset(screenSize.width * 0.65, screenSize.height * 0.75);
          _feetDetected = true;
          _detectionStatus = '✅ AR shoes ready! (Auto-positioned)';
        });
        return;
      } else {
        setState(() {
          _leftFootPosition = null;
          _rightFootPosition = null;
          _feetDetected = false;
          _detectionStatus = 'Point camera at your feet and step into view';
        });
        return;
      }
    }

    // Process the best pose
    final pose = poses.first;

    // Extract all foot-related landmarks
    final footLandmarks = _extractFootLandmarks(pose);

    // Validate that we have sufficient landmarks for realistic detection
    if (!_hasValidFootLandmarks(footLandmarks)) {
      if (_useSmartFallback) {
        setState(() {
          _leftFootPosition =
              Offset(screenSize.width * 0.35, screenSize.height * 0.75);
          _rightFootPosition =
              Offset(screenSize.width * 0.65, screenSize.height * 0.75);
          _feetDetected = true;
          _detectionStatus = '✅ AR shoes ready! (Auto-positioned)';
        });
        return;
      } else {
        setState(() {
          _detectionStatus = 'Step closer and show both feet clearly';
          _feetDetected = false;
        });
        return;
      }
    }

    // Calculate precise foot positions and measurements
    final leftFootData = _calculatePreciseFootPosition(
        footLandmarks, true, imageWidth, imageHeight, screenSize);
    final rightFootData = _calculatePreciseFootPosition(
        footLandmarks, false, imageWidth, imageHeight, screenSize);

    // Calculate realistic shoe size based on actual foot measurements
    final footSize =
        _calculateActualFootSize(footLandmarks, imageWidth, imageHeight);
    if (footSize != null) {
      setState(() {
        _shoeSize = footSize.clamp(0.8, 1.5);
      });
    }

    // Apply position smoothing for stable rendering
    _updatePositionHistory(leftFootData, rightFootData);

    // Require consecutive stable detections
    _consecutiveDetections++;

    if (_consecutiveDetections >= _minConsecutiveDetections) {
      final smoothedLeft = _getSmoothedPosition(_recentLeftFootPositions);
      final smoothedRight = _getSmoothedPosition(_recentRightFootPositions);

      setState(() {
        _leftFootPosition = smoothedLeft;
        _rightFootPosition = smoothedRight;
        _feetDetected = true;
        _detectionStatus = '✅ Perfect fit! Shoes are tracking your feet';
      });

      _lastSuccessfulDetection = DateTime.now();
    } else {
      setState(() {
        _detectionStatus = '👟 Analyzing your feet... keep steady';
        _feetDetected = false;
      });
    }
  }

  // Extract all foot-related landmarks with confidence scores
  Map<String, PoseLandmark?> _extractFootLandmarks(Pose pose) {
    return {
      'leftAnkle': pose.landmarks[PoseLandmarkType.leftAnkle],
      'rightAnkle': pose.landmarks[PoseLandmarkType.rightAnkle],
      'leftHeel': pose.landmarks[PoseLandmarkType.leftHeel],
      'rightHeel': pose.landmarks[PoseLandmarkType.rightHeel],
      'leftFootIndex': pose.landmarks[PoseLandmarkType.leftFootIndex],
      'rightFootIndex': pose.landmarks[PoseLandmarkType.rightFootIndex],
    };
  }

  // Validate that we have sufficient landmarks for realistic shoe placement
  bool _hasValidFootLandmarks(Map<String, PoseLandmark?> landmarks) {
    final leftAnkle = landmarks['leftAnkle'];
    final rightAnkle = landmarks['rightAnkle'];
    final leftHeel = landmarks['leftHeel'];
    final rightHeel = landmarks['rightHeel'];

    // We need at least both ankles OR both heels with good confidence
    bool hasAnkles = leftAnkle != null &&
        rightAnkle != null &&
        leftAnkle.likelihood >= _minFootConfidence &&
        rightAnkle.likelihood >= _minFootConfidence;

    bool hasHeels = leftHeel != null &&
        rightHeel != null &&
        leftHeel.likelihood >= _minFootConfidence &&
        rightHeel.likelihood >= _minFootConfidence;

    return hasAnkles || hasHeels;
  }

  // Calculate precise foot position using multiple landmarks
  Offset _calculatePreciseFootPosition(
    Map<String, PoseLandmark?> landmarks,
    bool isLeftFoot,
    int imageWidth,
    int imageHeight,
    Size screenSize,
  ) {
    final ankleKey = isLeftFoot ? 'leftAnkle' : 'rightAnkle';
    final heelKey = isLeftFoot ? 'leftHeel' : 'rightHeel';
    final toeKey = isLeftFoot ? 'leftFootIndex' : 'rightFootIndex';

    final ankle = landmarks[ankleKey];
    final heel = landmarks[heelKey];
    final toe = landmarks[toeKey];

    double footX, footY;

    // Priority 1: Use heel and toe for most accurate positioning
    if (heel != null &&
        toe != null &&
        heel.likelihood >= 0.4 &&
        toe.likelihood >= 0.4) {
      // Position shoe center between heel and toe
      footX = (heel.x + toe.x) / 2;
      footY = (heel.y + toe.y) / 2;
    }
    // Priority 2: Use ankle and heel
    else if (ankle != null &&
        heel != null &&
        ankle.likelihood >= 0.4 &&
        heel.likelihood >= 0.4) {
      // Position slightly forward from heel toward ankle
      footX = heel.x + (ankle.x - heel.x) * 0.3;
      footY = heel.y + (ankle.y - heel.y) * 0.3;
    }
    // Priority 3: Use ankle only (less accurate but workable)
    else if (ankle != null && ankle.likelihood >= _minFootConfidence) {
      footX = ankle.x;
      footY = ankle.y;
    }
    // Fallback: estimate based on other foot
    else {
      final otherAnkleKey = isLeftFoot ? 'rightAnkle' : 'leftAnkle';
      final otherAnkle = landmarks[otherAnkleKey];
      if (otherAnkle != null) {
        final offset = isLeftFoot ? -0.12 : 0.12; // Typical foot separation
        footX = otherAnkle.x + offset;
        footY = otherAnkle.y;
      } else {
        // Ultimate fallback
        footX = isLeftFoot ? 0.35 : 0.65;
        footY = 0.75;
      }
    }

    // Convert to screen coordinates
    final screenPos = _convertToScreenCoordinates(
        footX, footY, imageWidth, imageHeight, screenSize);

    // Position shoes on the ground (slightly below detected landmarks)
    return Offset(screenPos.dx, screenPos.dy + 15);
  }

  // Calculate actual foot size based on landmark measurements
  double? _calculateActualFootSize(
    Map<String, PoseLandmark?> landmarks,
    int imageWidth,
    int imageHeight,
  ) {
    // Try left foot first
    final leftHeel = landmarks['leftHeel'];
    final leftToe = landmarks['leftFootIndex'];

    if (leftHeel != null &&
        leftToe != null &&
        leftHeel.likelihood >= 0.4 &&
        leftToe.likelihood >= 0.4) {
      final footLengthNormalized =
          ((leftToe.x - leftHeel.x).abs() + (leftToe.y - leftHeel.y).abs()) / 2;

      // Convert normalized distance to realistic shoe size
      // Typical adult foot: 24-28cm, in normalized coords this is ~0.12-0.18
      if (footLengthNormalized > 0.08 && footLengthNormalized < 0.25) {
        return 0.7 + (footLengthNormalized * 3.5); // Realistic scaling
      }
    }

    // Try right foot
    final rightHeel = landmarks['rightHeel'];
    final rightToe = landmarks['rightFootIndex'];

    if (rightHeel != null &&
        rightToe != null &&
        rightHeel.likelihood >= 0.4 &&
        rightToe.likelihood >= 0.4) {
      final footLengthNormalized = ((rightToe.x - rightHeel.x).abs() +
              (rightToe.y - rightHeel.y).abs()) /
          2;

      if (footLengthNormalized > 0.08 && footLengthNormalized < 0.25) {
        return 0.7 + (footLengthNormalized * 3.5);
      }
    }

    // Fallback: use ankle distance
    final leftAnkle = landmarks['leftAnkle'];
    final rightAnkle = landmarks['rightAnkle'];

    if (leftAnkle != null && rightAnkle != null) {
      final ankleDistance = (rightAnkle.x - leftAnkle.x).abs();
      if (ankleDistance > 0.1 && ankleDistance < 0.4) {
        return 0.8 + (ankleDistance * 1.2); // Secondary scaling method
      }
    }

    return null; // No reliable measurement available
  }

  Offset _convertToScreenCoordinates(
    double x,
    double y,
    int imageWidth,
    int imageHeight,
    Size screenSize,
  ) {
    // ML Kit coordinates are in image pixel space, need to normalize then scale
    double normalizedX = x / imageWidth;
    double normalizedY = y / imageHeight;

    // Account for camera orientation and mirroring
    final bool isFrontCamera = _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;

    // Scale to screen dimensions
    double screenX = normalizedX * screenSize.width;
    double screenY = normalizedY * screenSize.height;

    // Mirror for front camera to match user's view
    if (isFrontCamera) {
      screenX = screenSize.width - screenX;
    }

    // Clamp coordinates to screen bounds with reasonable margins
    screenX = screenX.clamp(50.0, screenSize.width - 50.0);
    screenY = screenY.clamp(50.0, screenSize.height - 50.0);

    return Offset(screenX, screenY);
  }

  void _updatePositionHistory(Offset leftPos, Offset rightPos) {
    _recentLeftFootPositions.add(leftPos);
    _recentRightFootPositions.add(rightPos);

    if (_recentLeftFootPositions.length > _maxPositionHistory) {
      _recentLeftFootPositions.removeAt(0);
    }
    if (_recentRightFootPositions.length > _maxPositionHistory) {
      _recentRightFootPositions.removeAt(0);
    }
  }

  Offset _getSmoothedPosition(List<Offset> positions) {
    if (positions.isEmpty) return Offset.zero;

    double totalX = 0;
    double totalY = 0;

    for (final pos in positions) {
      totalX += pos.dx;
      totalY += pos.dy;
    }

    return Offset(totalX / positions.length, totalY / positions.length);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(_selectedCameraIndex);
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();

      // Request storage permission
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final result = await ImageGallerySaver.saveFile(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['isSuccess']
                  ? 'Photo saved to gallery!'
                  : 'Failed to save photo'),
              backgroundColor: result['isSuccess'] ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSizeControls() {
    setState(() {
      _showSizeControls = !_showSizeControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'AR Try-On: ${widget.productName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Camera Preview
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),

                // AR Shoes Overlay - Only show when feet are detected AND shoes are loaded
                if (_feetDetected &&
                    _preloadedShoeImage != null &&
                    _leftFootPosition != null &&
                    _rightFootPosition != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AssetShoesPainter(
                        leftFootPosition: _leftFootPosition!,
                        rightFootPosition: _rightFootPosition!,
                        shoeImagePath: _effectiveImagePath,
                        shoeSize: _shoeSize,
                        preloadedImage: _preloadedShoeImage,
                      ),
                    ),
                  ),

                // Loading indicator for image
                if (_isImageLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading shoe image...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Status Indicator
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _feetDetected && !_isImageLoading
                                ? Colors.green
                                : _isImageLoading
                                    ? Colors.blue
                                    : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _detectionStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Size adjustment controls (toggle-based like sunglasses)
                if (_showSizeControls)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.straighten,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Size:',
                              style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _shoeSize,
                              min: 0.5,
                              max: 2.0,
                              divisions: 30,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.grey,
                              label: '${(_shoeSize * 100).toInt()}%',
                              onChanged: (value) {
                                setState(() {
                                  _shoeSize = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom controls - like sunglasses
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Camera toggle button
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          child: IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _switchCamera,
                          ),
                        ),

                        // Capture photo button
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera,
                              color: Colors.black,
                              size: 32,
                            ),
                            onPressed: _capturePhoto,
                          ),
                        ),

                        // Size adjustment toggle button
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _showSizeControls
                              ? Colors.blue.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.4),
                          child: IconButton(
                            icon: const Icon(
                              Icons.straighten,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _toggleSizeControls,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  // Removed _buildControlButton - now using direct CircleAvatar buttons like sunglasses
}
