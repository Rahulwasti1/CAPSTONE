import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:capstone/service/asset_organizer_service.dart';
import 'asset_apparel_painter.dart';

class ARApparelScreen extends StatefulWidget {
  final String productName;
  final String productImage;
  final String apparelType;
  final String? selectedColor;
  final Map<String, dynamic>?
      productData; // Add product data for organized assets

  const ARApparelScreen({
    super.key,
    required this.productName,
    required this.productImage,
    required this.apparelType,
    this.selectedColor,
    this.productData, // Optional product data
  });

  @override
  State<ARApparelScreen> createState() => _ARApparelScreenState();
}

class _ARApparelScreenState extends State<ARApparelScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  int _selectedCameraIndex = 1; // Start with back camera (index 1)

  // Pose Detection
  PoseDetector? _poseDetector;

  // Detection timing
  int _lastDetectionTime = 0;
  static const int _detectionIntervalMs = 100; // 10 FPS

  // Simplified AR Variables
  Offset? _torsoCenter;
  double _torsoWidth = 0;
  double _torsoHeight = 0;
  bool _showApparel = false;

  // Status and feedback
  String _detectionStatus = 'Starting AR apparel...';

  // Image management
  ui.Image? _preloadedImage;
  bool _isImageReady = false;

  // Simple user controls - just one scaler
  double _apparelSize = 1.5; // Start a bit bigger
  bool _showSizeControls = false;

  @override
  void initState() {
    super.initState();
    _initializePoseDetector();
    _preloadApparelImageFast(); // Fast loading like shoes
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    _preloadedImage = null; // Clear image memory
    super.dispose();
  }

  Future<void> _initializePoseDetector() async {
    try {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.accurate,
        ),
      );
    } catch (e) {
      setState(() {
        _detectionStatus = 'Pose detector initialization failed';
      });
    }
  }

  /// Fast apparel loading - prioritizes local assets for instant loading
  Future<void> _preloadApparelImageFast() async {
    try {
      setState(() {
        _isImageReady = false;
        _detectionStatus = 'Loading AR apparel...';
      });

      ui.Image? loadedImage;

      // Priority 1: FAST - Load default apparel asset immediately
      loadedImage = await _tryLoadFromGenericAssets();

      // Set the fast-loading asset immediately
      if (loadedImage != null) {
        setState(() {
          _preloadedImage = loadedImage;
          _isImageReady = true;
          _detectionStatus = '👤 Position yourself in camera view';
        });

        // Try to upgrade with better images in background (non-blocking)
        _loadBetterApparelInBackground();
        return;
      }

      // Create placeholder if fast loading fails
      await _createPlaceholderImage();
      setState(() {
        _isImageReady = true;
        _detectionStatus = '👤 Position yourself in camera view';
      });
    } catch (e) {
      await _createPlaceholderImage();
      setState(() {
        _isImageReady = true;
        _detectionStatus = '👤 Position yourself in camera view';
      });
    }
  }

  /// Load better quality images in background without blocking UI
  Future<void> _loadBetterApparelInBackground() async {
    try {
      ui.Image? betterImage;

      // Try product-specific assets with timeout
      try {
        betterImage = await _tryLoadFromProductAssets().timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        // Continue if timeout or error
      }

      // Try network loading with timeout (only if product loading failed)
      if (betterImage == null && widget.productImage.isNotEmpty) {
        try {
          betterImage = await _tryLoadFromNetwork().timeout(
            const Duration(seconds: 3),
          );
        } catch (e) {
          // Continue if network loading fails
        }
      }

      // Update UI with better image if found
      if (mounted && betterImage != null) {
        setState(() {
          _preloadedImage = betterImage;
        });
      }
    } catch (e) {
      // Silently fail background loading - user already has working apparel
    }
  }

  Future<ui.Image?> _tryLoadFromProductAssets() async {
    try {
      List<String> possiblePaths = [];

      // Priority 1: Try organized document storage
      try {
        List<File> documentImages =
            await AssetOrganizerService.getProductImages(
          category: widget.productData?['category'] ?? 'Apparel',
          productId: widget.productData?['id'] ?? '',
          productTitle: widget.productName,
          selectedColor: widget.selectedColor,
        );

        if (documentImages.isNotEmpty) {
          // Try to load the first matching image
          for (File imageFile in documentImages) {
            try {
              final bytes = await imageFile.readAsBytes();
              final codec = await ui.instantiateImageCodec(bytes);
              final frame = await codec.getNextFrame();
              return frame.image;
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {}

      // Priority 2: Try loading from Firebase images (base64)
      if (widget.productData != null) {
        ui.Image? firebaseImage = await _tryLoadFromFirebaseImages();
        if (firebaseImage != null) {
          return firebaseImage;
        }
      }

      // Priority 3: Try organized asset paths from product data (legacy)
      if (widget.productData != null &&
          widget.productData!['assetPaths'] != null) {
        List<String> organizedPaths =
            List<String>.from(widget.productData!['assetPaths']);

        // Found organized asset paths (legacy)

        // Filter by selected color if available
        if (widget.selectedColor != null && widget.selectedColor!.isNotEmpty) {
          String colorName = widget.selectedColor!;

          // Try to find asset path matching the selected color
          for (String assetPath in organizedPaths) {
            if (assetPath.toLowerCase().contains(colorName.toLowerCase())) {
              possiblePaths.add(assetPath);
            }
          }
        }

        // Add all organized paths as fallback
        possiblePaths.addAll(organizedPaths);
      }

      // Priority 2: Legacy product-specific paths with selected color
      if (widget.selectedColor != null && widget.selectedColor!.isNotEmpty) {
        String colorName = widget.selectedColor!;
        // Try exact format: ProductName(Color).png
        possiblePaths.addAll([
          'assets/effects/apparel/${widget.productName}($colorName).png',
          'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}($colorName).png',
          'assets/effects/apparel/${widget.productName}(${colorName.toLowerCase()}).png',
          'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}(${colorName.toLowerCase()}).png',
          'assets/effects/apparel/${widget.productName}(${colorName.toUpperCase()}).png',
          'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}(${colorName.toUpperCase()}).png',
          // Try with first letter capitalized
          'assets/effects/apparel/${widget.productName}(${colorName[0].toUpperCase()}${colorName.substring(1).toLowerCase()}).png',
          'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}(${colorName[0].toUpperCase()}${colorName.substring(1).toLowerCase()}).png',
        ]);
      }

      // Priority 3: Default colors (Blue and Black as seen in the directory)
      possiblePaths.addAll([
        'assets/effects/apparel/${widget.productName}(Blue).png',
        'assets/effects/apparel/${widget.productName}(Black).png',
        'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}(Blue).png',
        'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}(Black).png',
        'assets/effects/apparel/${widget.productName}.png',
        'assets/effects/apparel/${widget.productName.replaceAll(' ', '')}.png',
      ]);

      for (String path in possiblePaths) {
        try {
          final ByteData data = await rootBundle.load(path);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();
          return fi.image;
        } catch (e) {
          // Continue to next path
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image?> _tryLoadFromFirebaseImages() async {
    try {
      if (widget.productData == null) return null;

      List<String> imageURLs = [];
      if (widget.productData!['imageURLs'] != null) {
        imageURLs = List<String>.from(widget.productData!['imageURLs']);
      }

      if (imageURLs.isEmpty) return null;

      final String base64Image = imageURLs.first;
      final Uint8List bytes = base64Decode(base64Image);
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      return fi.image;
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image?> _tryLoadFromNetwork() async {
    try {
      final response = await http
          .get(Uri.parse(widget.productImage))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        return frameInfo.image;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image?> _tryLoadFromGenericAssets() async {
    try {
      // Try generic apparel assets
      List<String> genericPaths = [
        'assets/effects/apparel/RegularFit(Blue).png',
        'assets/effects/apparel/RegularFit(Black).png',
        'assets/images/apparel/tshirt_blue.png',
      ];

      for (String path in genericPaths) {
        try {
          final ByteData data = await rootBundle.load(path);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();
          return fi.image;
        } catch (e) {
          // Continue to next path
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _createPlaceholderImage() async {
    try {
      // Create a simple colored rectangle as placeholder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.blue.withValues(alpha: 179);

      canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), paint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 200);

      setState(() {
        _preloadedImage = image;
      });
    } catch (e) {}
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
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
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _detectionStatus = 'Stand in view and face the camera';
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

      final poses = await _poseDetector!.processImage(inputImage);

      if (mounted) {
        _processPoseDetectionResults(poses, image);
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

  void _processPoseDetectionResults(List<Pose> poses, CameraImage image) async {
    // Use only the first reliable pose for better performance
    if (poses.isEmpty) {
      setState(() {
        _torsoCenter = null;
        _torsoWidth = 0;
        _torsoHeight = 0;
        _showApparel = false;
        _detectionStatus = "Position yourself in front of the camera";
      });
      return;
    }

    final pose = poses.first;

    // Simple pose validation for fast detection
    final isValid = _validateSimplePose(pose, image);

    if (isValid) {
      setState(() {
        _showApparel = true;
        _detectionStatus =
            "✅ ${widget.apparelType.toUpperCase()} ready - adjust size as needed";
      });
    } else {
      setState(() {
        _showApparel = false;
        _detectionStatus = "👤 Position yourself in camera view";
      });
    }
  }

  // Simple body detection for fast AR experience
  bool _validateSimplePose(Pose pose, CameraImage image) {
    final screenSize = MediaQuery.of(context).size;

    // Get basic landmarks - more forgiving
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Basic validation
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return false;
    }

    // Forgiving confidence threshold
    if (leftShoulder.likelihood < 0.5 ||
        rightShoulder.likelihood < 0.5 ||
        leftHip.likelihood < 0.5 ||
        rightHip.likelihood < 0.5) {
      return false;
    }

    // Calculate simple measurements
    return _calculateSimpleBodyMeasurements(
        leftShoulder, rightShoulder, leftHip, rightHip, image, screenSize);
  }

  // Simple body measurements for easy apparel fitting
  bool _calculateSimpleBodyMeasurements(
      PoseLandmark leftShoulder,
      PoseLandmark rightShoulder,
      PoseLandmark leftHip,
      PoseLandmark rightHip,
      CameraImage image,
      Size screenSize) {
    // Convert coordinates to screen space
    final leftShoulderScreen =
        _convertCoordinate(leftShoulder, image, screenSize);
    final rightShoulderScreen =
        _convertCoordinate(rightShoulder, image, screenSize);
    final leftHipScreen = _convertCoordinate(leftHip, image, screenSize);
    final rightHipScreen = _convertCoordinate(rightHip, image, screenSize);

    // Calculate simple torso center and dimensions
    final torsoCenter = Offset(
      (leftShoulderScreen.dx +
              rightShoulderScreen.dx +
              leftHipScreen.dx +
              rightHipScreen.dx) /
          4,
      (leftShoulderScreen.dy +
              rightShoulderScreen.dy +
              leftHipScreen.dy +
              rightHipScreen.dy) /
          4,
    );

    final shoulderWidth =
        (rightShoulderScreen.dx - leftShoulderScreen.dx).abs();
    final hipWidth = (rightHipScreen.dx - leftHipScreen.dx).abs();
    final torsoWidth = (shoulderWidth + hipWidth) / 2;
    final torsoHeight = ((leftHipScreen.dy + rightHipScreen.dy) / 2 -
            (leftShoulderScreen.dy + rightShoulderScreen.dy) / 2)
        .abs();

    // Simple validation - not too small, not too big
    if (torsoWidth < screenSize.width * 0.1 ||
        torsoHeight < screenSize.height * 0.15) {
      return false;
    }

    if (torsoWidth > screenSize.width * 0.8 ||
        torsoHeight > screenSize.height * 0.8) {
      return false;
    }

    // Update state with measurements
    _torsoCenter = torsoCenter;
    _torsoWidth = torsoWidth;
    _torsoHeight = torsoHeight;

    return true;
  }

  // Optimized coordinate conversion
  Offset _convertCoordinate(
      PoseLandmark landmark, CameraImage image, Size screenSize) {
    final double x = landmark.x * screenSize.width / image.width;
    final double y = landmark.y * screenSize.height / image.height;
    return Offset(x, y);
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

                // AR Apparel Overlay - simplified
                if (_showApparel &&
                    _torsoCenter != null &&
                    _torsoWidth > 0 &&
                    _torsoHeight > 0 &&
                    _isImageReady)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AssetApparelPainter(
                        torsoCenter: _torsoCenter!,
                        torsoWidth: _torsoWidth,
                        torsoHeight: _torsoHeight,
                        apparelImagePath: widget.productImage,
                        apparelSize: _apparelSize,
                        apparelType: widget.apparelType,
                        preloadedImage: _preloadedImage,
                        shoulderCenter:
                            null, // Simplified - no complex measurements
                        shoulderWidth: 0,
                        chestWidth: 0,
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
                      color: Colors.black.withValues(alpha: 179),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _torsoCenter != null
                                ? Colors.green
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

                // Simple Size Control - like other AR features
                if (_showSizeControls)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.straighten,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              const Text('Size:',
                                  style: TextStyle(color: Colors.white)),
                              Expanded(
                                child: Slider(
                                  value: _apparelSize,
                                  min: 0.5,
                                  max: 2.5,
                                  divisions: 40,
                                  activeColor: Colors.blue,
                                  inactiveColor: Colors.grey,
                                  label: '${(_apparelSize * 100).toInt()}%',
                                  onChanged: (value) {
                                    setState(() {
                                      _apparelSize = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Controls
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Camera flip button
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.flip_camera_ios,
                                color: Colors.white, size: 28),
                            onPressed: _switchCamera,
                          ),
                        ),

                        // Capture button
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.black, size: 35),
                            onPressed: _capturePhoto,
                          ),
                        ),

                        // Size adjustment button
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _showSizeControls
                              ? Colors.blue.withValues(alpha: 0.6)
                              : Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.straighten,
                                color: Colors.white, size: 28),
                            onPressed: () => setState(
                                () => _showSizeControls = !_showSizeControls),
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
}
