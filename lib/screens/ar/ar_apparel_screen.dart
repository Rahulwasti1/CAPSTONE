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

  // Apparel rendering
  double _apparelSize = 1.0;
  bool _showApparel = true;
  String _detectionStatus = 'Initializing camera...';

  // Position smoothing
  final List<Offset> _recentTorsoPositions = [];
  final List<double> _recentTorsoWidths = [];
  final List<double> _recentTorsoHeights = [];
  static const int _maxPositionHistory = 5;

  // Image loading
  ui.Image? _preloadedImage;
  bool _isImageReady = false;
  String _effectiveImagePath = '';

  // Body positions for apparel placement
  Offset? _torsoCenter;
  double _torsoWidth = 0;
  double _torsoHeight = 0;

  @override
  void initState() {
    super.initState();
    _initializePoseDetector();
    _preloadApparelImage();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
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

  Future<void> _preloadApparelImage() async {
    try {
      setState(() {
        _isImageReady = false;
      });

      ui.Image? loadedImage;

      // Try loading from product-specific assets first (like watches system)
      loadedImage = await _tryLoadFromProductAssets();
      if (loadedImage != null) {
        setState(() {
          _preloadedImage = loadedImage;
          _effectiveImagePath = 'product_asset';
          _isImageReady = true;
        });
        return;
      }

      // Try loading from network URL if provided
      if (widget.productImage.isNotEmpty &&
          (widget.productImage.startsWith('http://') ||
              widget.productImage.startsWith('https://'))) {
        loadedImage = await _tryLoadFromNetwork();
        if (loadedImage != null) {
          setState(() {
            _preloadedImage = loadedImage;
            _effectiveImagePath = widget.productImage;
            _isImageReady = true;
          });
          return;
        }
      }

      // Try loading from generic apparel assets
      loadedImage = await _tryLoadFromGenericAssets();
      if (loadedImage != null) {
        setState(() {
          _preloadedImage = loadedImage;
          _effectiveImagePath = 'generic_asset';
          _isImageReady = true;
        });
        return;
      }

      // Create placeholder if all else fails
      await _createPlaceholderImage();
      setState(() {
        _isImageReady = true;
      });
    } catch (e) {
      await _createPlaceholderImage();
      setState(() {
        _isImageReady = true;
      });
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
          productTitle: widget.productName ?? '',
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
        _effectiveImagePath = 'placeholder';
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
      setState(() {
        _detectionStatus = 'No person detected - step into view';
      });
      return;
    }

    final pose = poses.first;

    // Get key body landmarks for apparel placement
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      setState(() {
        _detectionStatus = 'Turn to face the camera clearly';
      });
      return;
    }

    // Check confidence levels
    if (leftShoulder.likelihood < 0.6 ||
        rightShoulder.likelihood < 0.6 ||
        leftHip.likelihood < 0.6 ||
        rightHip.likelihood < 0.6) {
      setState(() {
        _detectionStatus = 'Stand clearly in front of camera';
      });
      return;
    }

    // Convert camera coordinates to screen coordinates
    final screenSize = MediaQuery.of(context).size;
    final leftShoulderScreen = _convertToScreenCoordinates(
      leftShoulder.x,
      leftShoulder.y,
      imageWidth,
      imageHeight,
      screenSize,
    );
    final rightShoulderScreen = _convertToScreenCoordinates(
      rightShoulder.x,
      rightShoulder.y,
      imageWidth,
      imageHeight,
      screenSize,
    );
    final leftHipScreen = _convertToScreenCoordinates(
      leftHip.x,
      leftHip.y,
      imageWidth,
      imageHeight,
      screenSize,
    );
    final rightHipScreen = _convertToScreenCoordinates(
      rightHip.x,
      rightHip.y,
      imageWidth,
      imageHeight,
      screenSize,
    );

    // Calculate torso dimensions and center
    final shoulderCenter = Offset(
      (leftShoulderScreen.dx + rightShoulderScreen.dx) / 2,
      (leftShoulderScreen.dy + rightShoulderScreen.dy) / 2,
    );

    final hipCenter = Offset(
      (leftHipScreen.dx + rightHipScreen.dx) / 2,
      (leftHipScreen.dy + rightHipScreen.dy) / 2,
    );

    final torsoCenter = Offset(
      (shoulderCenter.dx + hipCenter.dx) / 2,
      (shoulderCenter.dy + hipCenter.dy) / 2,
    );

    final torsoWidth = (rightShoulderScreen.dx - leftShoulderScreen.dx).abs();
    final torsoHeight = (hipCenter.dy - shoulderCenter.dy).abs();

    // Apply position smoothing
    _updatePositionHistory(torsoCenter, torsoWidth, torsoHeight);

    setState(() {
      _detectionStatus = 'Body detected - AR apparel active';
    });
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

    double screenX = x * screenSize.width / imageWidth;
    double screenY = y * screenSize.height / imageHeight;

    // Mirror for front camera
    if (isFrontCamera) {
      screenX = screenSize.width - screenX;
    }

    return Offset(screenX, screenY);
  }

  void _updatePositionHistory(Offset torsoPos, double width, double height) {
    _recentTorsoPositions.add(torsoPos);
    _recentTorsoWidths.add(width);
    _recentTorsoHeights.add(height);

    if (_recentTorsoPositions.length > _maxPositionHistory) {
      _recentTorsoPositions.removeAt(0);
      _recentTorsoWidths.removeAt(0);
      _recentTorsoHeights.removeAt(0);
    }
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

                // AR Apparel Overlay
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
                        apparelImagePath: _effectiveImagePath,
                        apparelSize: _apparelSize,
                        apparelType: widget.apparelType,
                        preloadedImage: _preloadedImage,
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
                            Text(
                              '${widget.apparelType.toUpperCase()} Size',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('50%',
                                    style: TextStyle(color: Colors.white70)),
                                Expanded(
                                  child: Slider(
                                    value: _apparelSize,
                                    min: 0.5,
                                    max: 2.0,
                                    divisions: 15,
                                    activeColor: Colors.purple,
                                    onChanged: (value) {
                                      setState(() {
                                        _apparelSize = value;
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
