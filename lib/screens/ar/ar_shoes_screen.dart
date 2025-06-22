import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:capstone/service/asset_organizer_service.dart';
import 'asset_shoes_painter.dart';

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
  int _selectedCameraIndex = 0;

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
  Size _cameraImageSize = Size.zero;

  // Detection timing
  int _lastDetectionTime = 0;
  static const int _detectionIntervalMs = 100; // 10 FPS

  // Shoe rendering
  double _shoeSize = 1.0;
  bool _showShoes = true;
  String _detectionStatus = 'Initializing...';
  String _effectiveImagePath = '';

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
    try {
      // Priority 1: Try organized document storage
      List<File> documentImages = await AssetOrganizerService.getProductImages(
        category: 'Shoes',
        productId: widget.productId ??
            widget.productName, // Use productId if available, fallback to name
        productTitle: widget.productName,
        selectedColor: null,
      );

      if (documentImages.isNotEmpty) {
        _effectiveImagePath = documentImages.first.path;
        return;
      }

      // Priority 2: Try loading from Firebase images (base64)
      if (widget.productData != null) {
        bool firebaseLoaded = await _tryLoadFromFirebaseImages();
        if (firebaseLoaded) {
          return;
        }
      }

      // Priority 3: Use smart shoe selection from assets/effects/shoes/
      _effectiveImagePath = _selectBestShoeAsset();
    } catch (e) {
      _effectiveImagePath = 'assets/effects/shoes/Black.png';
    }
  }

  String _selectBestShoeAsset() {
    final String productTitle = widget.productName.toLowerCase();

    // Available shoe assets in assets/effects/shoes/
    final Map<String, String> availableShoes = {
      'Black.png': 'assets/effects/shoes/Black.png',
      'Purple.png': 'assets/effects/shoes/Purple.png',
    };

    // Smart matching logic
    if (productTitle.contains('black') || productTitle.contains('dark')) {
      return availableShoes['Black.png']!;
    } else if (productTitle.contains('purple') ||
        productTitle.contains('violet')) {
      return availableShoes['Purple.png']!;
    } else {
      // Default selection - use hash for variety
      final List<String> shoeOptions = availableShoes.values.toList();
      final int index = productTitle.hashCode.abs() % shoeOptions.length;
      return shoeOptions[index];
    }
  }

  Future<bool> _tryLoadFromFirebaseImages() async {
    try {
      if (widget.productData == null) return false;

      List<String> imageURLs = [];
      if (widget.productData!['imageURLs'] != null) {
        imageURLs = List<String>.from(widget.productData!['imageURLs']);
      }

      if (imageURLs.isEmpty) return false;

      final String base64Image = imageURLs.first;
      final bytes = base64Decode(base64Image);

      // Create a temporary file to save the base64 image
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/temp_shoe_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      _effectiveImagePath = tempFile.path;
      return true;
    } catch (e) {
      return false;
    }
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
      setState(() {
        _detectionStatus = 'No person detected - step into view';
        _leftFootPosition = null;
        _rightFootPosition = null;
      });
      return;
    }

    final pose = poses.first;

    // Get ankle positions (closest to feet)
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftAnkle == null || rightAnkle == null) {
      setState(() {
        _detectionStatus = 'Show your feet clearly';
      });
      return;
    }

    // Check confidence levels
    if (leftAnkle.likelihood < 0.5 || rightAnkle.likelihood < 0.5) {
      setState(() {
        _detectionStatus = 'Position your feet clearly';
      });
      return;
    }

    // Convert camera coordinates to screen coordinates
    final screenSize = MediaQuery.of(context).size;
    final leftScreenPos = _convertToScreenCoordinates(
      leftAnkle.x,
      leftAnkle.y,
      imageWidth,
      imageHeight,
      screenSize,
    );
    final rightScreenPos = _convertToScreenCoordinates(
      rightAnkle.x,
      rightAnkle.y,
      imageWidth,
      imageHeight,
      screenSize,
    );

    // Apply position smoothing
    _updatePositionHistory(leftScreenPos, rightScreenPos);

    setState(() {
      _leftFootPosition = _getSmoothedPosition(_recentLeftFootPositions);
      _rightFootPosition = _getSmoothedPosition(_recentRightFootPositions);
      _detectionStatus = 'Feet detected - AR shoes active';
      _cameraImageSize = Size(imageWidth.toDouble(), imageHeight.toDouble());
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

    // Adjust for foot position (shoes go slightly below ankle)
    screenY += 40; // Offset shoes below ankle

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
                if (_showShoes &&
                    _leftFootPosition != null &&
                    _rightFootPosition != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AssetShoesPainter(
                        leftFootPosition: _leftFootPosition!,
                        rightFootPosition: _rightFootPosition!,
                        shoeImagePath: _effectiveImagePath.isNotEmpty
                            ? _effectiveImagePath
                            : widget.productImage,
                        shoeSize: _shoeSize,
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
                            color: _leftFootPosition != null &&
                                    _rightFootPosition != null
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
                            icon: _showShoes
                                ? Icons.visibility
                                : Icons.visibility_off,
                            label: _showShoes ? 'Hide' : 'Show',
                            onPressed: () {
                              setState(() {
                                _showShoes = !_showShoes;
                              });
                            },
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
