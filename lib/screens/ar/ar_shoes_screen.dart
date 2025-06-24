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

  String _detectionStatus = 'Initializing...';
  String _effectiveImagePath = '';

  // Enhanced foot detection parameters
  static const double _minFootConfidence =
      0.1; // Ultra low confidence for maximum detection
  static const int _minConsecutiveDetections = 1; // Immediate detection
  int _consecutiveDetections = 0;
  bool _feetDetected = false;

  // Image loading state
  ui.Image? _preloadedShoeImage;
  bool _isImageLoading = true;

  // Position smoothing
  final List<Offset> _recentLeftFootPositions = [];
  final List<Offset> _recentRightFootPositions = [];
  static const int _maxPositionHistory = 5;

  @override
  void initState() {
    super.initState();
    _loadShoeImage();
    _initializeCamera();
  }

  Future<void> _loadShoeImage() async {
    setState(() {
      _isImageLoading = true;
      _detectionStatus = 'Loading shoe image...';
    });

    try {
      ui.Image? loadedImage;

      // Priority 1: Try organized document storage
      List<File> documentImages = await AssetOrganizerService.getProductImages(
        category: 'Shoes',
        productId: widget.productId ?? widget.productName,
        productTitle: widget.productName,
        selectedColor: null,
      );

      if (documentImages.isNotEmpty) {
        _effectiveImagePath = documentImages.first.path;
        loadedImage = await _loadImageFromFile(documentImages.first);
      }

      // Priority 2: Try loading from Firebase images (base64)
      if (loadedImage == null && widget.productImage.isNotEmpty) {
        loadedImage = await _tryLoadFromFirebaseImages();
      }

      // Priority 3: Smart shoe selection from assets
      if (loadedImage == null) {
        _effectiveImagePath = _selectBestShoeAsset();
        loadedImage = await _loadImageFromAssets(_effectiveImagePath);

        // If still null, force load the black shoe as ultimate fallback
        if (loadedImage == null) {
          _effectiveImagePath = 'assets/effects/shoes/Black.png';
          loadedImage = await _loadImageFromAssets(_effectiveImagePath);
        }
      }

      if (mounted) {
        setState(() {
          _preloadedShoeImage = loadedImage;
          _isImageLoading = false;
          _detectionStatus = 'Show your feet to try on shoes';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _effectiveImagePath = 'assets/effects/shoes/Black.png';
          _isImageLoading = false;
          _detectionStatus = 'Using default shoes - show your feet';
        });
        // Load default image
        _loadImageFromAssets(_effectiveImagePath).then((image) {
          if (mounted) {
            setState(() {
              _preloadedShoeImage = image;
            });
          }
        });
      }
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
      ResolutionPreset.high, // Better resolution for foot detection
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _detectionStatus = 'Stand in view and show your feet';
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
    if (poses.isEmpty) {
      _consecutiveDetections = 0;
      setState(() {
        _detectionStatus = 'No person detected - step into view';
        _leftFootPosition = null;
        _rightFootPosition = null;
        _feetDetected = false;
      });
      return;
    }

    final pose = poses.first;

    // Get foot-related landmarks for better accuracy
    PoseLandmark? leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    PoseLandmark? rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
    final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
    final leftFootIndex = pose.landmarks[PoseLandmarkType.leftFootIndex];
    final rightFootIndex = pose.landmarks[PoseLandmarkType.rightFootIndex];

    // Validate foot detection with multiple landmarks
    bool leftFootValid =
        _validateFootLandmarks(leftAnkle, leftHeel, leftFootIndex);
    bool rightFootValid =
        _validateFootLandmarks(rightAnkle, rightHeel, rightFootIndex);

    if (!leftFootValid && !rightFootValid) {
      _consecutiveDetections = 0;
      setState(() {
        _detectionStatus = 'Show your feet clearly in the camera';
        _feetDetected = false;
      });
      return;
    }

    // Allow detection even if only one foot is valid (use ankle position for missing foot)
    if (!leftFootValid && rightFootValid && rightAnkle != null) {
      // Estimate left foot position from right foot
      leftAnkle = PoseLandmark(
        type: PoseLandmarkType.leftAnkle,
        x: rightAnkle.x - 0.2, // Approximate left foot position
        y: rightAnkle.y,
        z: rightAnkle.z,
        likelihood: rightAnkle.likelihood * 0.8,
      );
    } else if (!rightFootValid && leftFootValid && leftAnkle != null) {
      // Estimate right foot position from left foot
      rightAnkle = PoseLandmark(
        type: PoseLandmarkType.rightAnkle,
        x: leftAnkle.x + 0.2, // Approximate right foot position
        y: leftAnkle.y,
        z: leftAnkle.z,
        likelihood: leftAnkle.likelihood * 0.8,
      );
    }

    // Calculate optimal foot positions using multiple landmarks
    final screenSize = MediaQuery.of(context).size;
    final leftScreenPos = _calculateOptimalFootPosition(leftAnkle!, leftHeel,
        leftFootIndex, imageWidth, imageHeight, screenSize, true);
    final rightScreenPos = _calculateOptimalFootPosition(rightAnkle!, rightHeel,
        rightFootIndex, imageWidth, imageHeight, screenSize, false);

    // Apply position smoothing
    _updatePositionHistory(leftScreenPos, rightScreenPos);

    // Require consecutive stable detections
    _consecutiveDetections++;

    if (_consecutiveDetections >= _minConsecutiveDetections) {
      setState(() {
        _leftFootPosition = _getSmoothedPosition(_recentLeftFootPositions);
        _rightFootPosition = _getSmoothedPosition(_recentRightFootPositions);
        _detectionStatus =
            'Feet detected - AR shoes active (Image: ${_preloadedShoeImage != null ? "✓" : "✗"})';
        _feetDetected = true;
      });
    } else {
      setState(() {
        _detectionStatus =
            'Stabilizing foot detection... $_consecutiveDetections/$_minConsecutiveDetections';
        _feetDetected = false;
      });
    }
  }

  bool _validateFootLandmarks(
      PoseLandmark? ankle, PoseLandmark? heel, PoseLandmark? footIndex) {
    // Accept if we have ANY foot-related landmark
    if (ankle != null && ankle.likelihood >= _minFootConfidence) return true;
    if (heel != null && heel.likelihood >= 0.05) return true;
    if (footIndex != null && footIndex.likelihood >= 0.05) return true;

    return false;
  }

  Offset _calculateOptimalFootPosition(
    PoseLandmark ankle,
    PoseLandmark? heel,
    PoseLandmark? footIndex,
    int imageWidth,
    int imageHeight,
    Size screenSize,
    bool isLeftFoot,
  ) {
    // Use ankle as primary position
    double footX = ankle.x;
    double footY = ankle.y;

    // If heel is available, position shoe between ankle and heel
    if (heel != null && heel.likelihood > 0.3) {
      footX = (ankle.x + heel.x) / 2;
      footY = (ankle.y + heel.y) / 2;
    }

    // If foot index is available, adjust for shoe length
    if (footIndex != null && footIndex.likelihood > 0.3) {
      // Position shoe center between heel and toe
      if (heel != null) {
        footX = (heel.x + footIndex.x) / 2;
        footY = (heel.y + footIndex.y) / 2;
      } else {
        // Estimate heel position from ankle and foot index
        footX = (ankle.x + footIndex.x) / 2;
        footY = (ankle.y + footIndex.y) / 2;
      }
    }

    return _convertToScreenCoordinates(
        footX, footY, imageWidth, imageHeight, screenSize);
  }

  Offset _convertToScreenCoordinates(
    double x,
    double y,
    int imageWidth,
    int imageHeight,
    Size screenSize,
  ) {
    // Account for camera orientation and mirroring
    final bool isFrontCamera = _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;

    // Convert normalized coordinates (0-1) to screen coordinates
    double screenX = x * screenSize.width;
    double screenY = y * screenSize.height;

    // Mirror for front camera
    if (isFrontCamera) {
      screenX = screenSize.width - screenX;
    }

    // Adjust for foot position - shoes should be centered on feet
    screenY += 10; // Small offset to center shoes on feet

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

                // AR Shoes Overlay
                // Always show shoes - either at detected positions or fallback positions
                Positioned.fill(
                  child: CustomPaint(
                    painter: AssetShoesPainter(
                      leftFootPosition: _leftFootPosition ??
                          Offset(MediaQuery.of(context).size.width * 0.35,
                              MediaQuery.of(context).size.height * 0.8),
                      rightFootPosition: _rightFootPosition ??
                          Offset(MediaQuery.of(context).size.width * 0.65,
                              MediaQuery.of(context).size.height * 0.8),
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

                // Controls
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Size Control
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Shoe Size',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('50%',
                                    style: TextStyle(color: Colors.white70)),
                                Expanded(
                                  child: Slider(
                                    value: _shoeSize,
                                    min: 0.5,
                                    max: 2.0,
                                    divisions: 15,
                                    activeColor: Colors.blue,
                                    onChanged: (value) {
                                      setState(() {
                                        _shoeSize = value;
                                      });
                                    },
                                  ),
                                ),
                                const Text('200%',
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.flip_camera_ios,
                            label: 'Switch',
                            onPressed: _switchCamera,
                          ),
                          _buildControlButton(
                            icon: Icons.camera_alt,
                            label: 'Capture',
                            onPressed: _capturePhoto,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
