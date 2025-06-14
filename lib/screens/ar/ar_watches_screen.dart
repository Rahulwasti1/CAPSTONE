import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:capstone/screens/ar/asset_watches_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ARWatchesScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productImage;
  final String productTitle;
  final String productId;
  final Map<String, dynamic>? productData;

  const ARWatchesScreen({
    super.key,
    required this.cameras,
    required this.productImage,
    required this.productTitle,
    required this.productId,
    this.productData,
  });

  @override
  State<ARWatchesScreen> createState() => _ARWatchesScreenState();
}

class _ARWatchesScreenState extends State<ARWatchesScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isUsingFrontCamera = true;
  String? _errorMessage;
  ui.Image? _watchImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // Simple size controls like sunglasses - START BIG so users can reduce
  double _widthScale = 1.5;
  double _heightScale = 1.5;
  bool _showSizeControls = false;

  // Pose detection for wrist detection
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  bool _wristDetected = false;
  Offset? _wristPosition;
  Size? _cameraImageSize;

  // Smoothing and stability improvements
  DateTime? _lastDetectionTime;
  static const int _detectionIntervalMs =
      150; // Slightly faster for better responsiveness
  List<Offset> _recentWristPositions = []; // For position smoothing
  static const int _maxRecentPositions = 3; // Reduced for faster response
  static const double _minConfidence = 0.5; // Lowered for better detection
  int _consecutiveDetections = 0; // Count consecutive detections
  static const int _minConsecutiveDetections =
      2; // Reduced for faster activation

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePoseDetector();
    _loadWatchImage();
    _initializeCamera(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentCamera();
    _poseDetector?.close();
    super.dispose();
  }

  /// Initialize pose detector for wrist detection
  void _initializePoseDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.stream,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null) {
        _initializeCamera(_isUsingFrontCamera);
      }
    }
  }

  /// Load watch image using dynamic loading system
  Future<void> _loadWatchImage() async {
    try {
      setState(() {
        _isImageLoading = true;
        _errorMessage = null;
      });

      developer.log("🔥 LOADING WATCH IMAGE");
      developer
          .log("Product: '${widget.productTitle}' (ID: ${widget.productId})");

      ui.Image? loadedImage;

      // Try loading from Firebase images (base64)
      if (widget.productData != null) {
        loadedImage = await _tryLoadFromFirebaseImages();
        if (loadedImage != null) {
          setState(() {
            _watchImage = loadedImage;
            _isImageLoading = false;
          });
          developer.log("✅ Loaded watch from Firebase images");
          return;
        }
      }

      // Try loading from product assets
      loadedImage = await _tryLoadFromProductAssets();
      if (loadedImage != null) {
        setState(() {
          _watchImage = loadedImage;
          _isImageLoading = false;
        });
        developer.log("✅ Loaded watch from product assets");
        return;
      }

      // Try loading from generic assets
      loadedImage = await _tryLoadFromGenericAssets();
      if (loadedImage != null) {
        setState(() {
          _watchImage = loadedImage;
          _isImageLoading = false;
        });
        developer.log("✅ Loaded generic watch asset");
        return;
      }

      // Create placeholder
      await _createPlaceholderImage();
      setState(() {
        _isImageLoading = false;
      });
    } catch (e) {
      developer.log("❌ Watch image loading failed: $e");
      await _createPlaceholderImage();
      setState(() {
        _isImageLoading = false;
        _errorMessage = null;
      });
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

  Future<ui.Image?> _tryLoadFromProductAssets() async {
    try {
      final String productAssetPath =
          'assets/products/${widget.productId}/watch.png';
      final ByteData data = await rootBundle.load(productAssetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      return fi.image;
    } catch (e) {
      return null;
    }
  }

  Future<ui.Image?> _tryLoadFromGenericAssets() async {
    try {
      final String lowerTitle = widget.productTitle.toLowerCase();
      String imagePath;

      if (lowerTitle.contains('diesel') || lowerTitle.contains('chief')) {
        imagePath = 'assets/effects/watches/Diesel Mega Chief.png';
      } else if (lowerTitle.contains('guess') ||
          lowerTitle.contains('letter')) {
        imagePath = 'assets/effects/watches/Guess Letterm.png';
      } else {
        imagePath = 'assets/effects/watches/watch.png'; // Default
      }

      final ByteData data = await rootBundle.load(imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      return fi.image;
    } catch (e) {
      return null;
    }
  }

  Future<void> _createPlaceholderImage() async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = const Size(200, 200);

      // Draw watch shape
      final paint = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      // Watch circle
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 80, paint);

      // Watch hands
      canvas.drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width / 2, size.height / 2 - 40),
        paint,
      );
      canvas.drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width / 2 + 30, size.height / 2),
        paint,
      );

      final picture = pictureRecorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());

      if (mounted) {
        setState(() {
          _watchImage = img;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load watch image.";
        });
      }
    }
  }

  Future<void> _initializeCamera(bool useFrontCamera) async {
    await _disposeCurrentCamera();

    try {
      final camera =
          useFrontCamera ? widget.cameras.first : widget.cameras.last;
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      _cameraController = controller;
      await controller.initialize();

      if (!mounted) return;

      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFlashMode(FlashMode.off);

      _isUsingFrontCamera = useFrontCamera;
      _cameraActive = true;

      // Start image stream for pose detection
      controller.startImageStream(_processCameraImage);

      setState(() {
        _isInitializing = false;
      });

      developer
          .log("📷 Camera initialized: ${useFrontCamera ? 'FRONT' : 'BACK'}");
    } on CameraException catch (e) {
      developer.log("Camera exception: ${e.code}: ${e.description}");
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = "Camera error: ${e.description}";
        });
      }
    } catch (e) {
      developer.log("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = "Failed to initialize camera: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraController != null) {
      _cameraActive = false;
      try {
        // Stop image stream before disposing
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
          developer.log("📷 Camera controller disposed");
        }
      } catch (e) {
        developer.log("❌ Error disposing camera: $e");
      }
      _cameraController = null;
    }
  }

  /// Process camera image for pose detection with error handling
  Future<void> _processCameraImage(CameraImage image) async {
    // Skip if already detecting or too soon since last detection
    if (_isDetecting) return;

    final now = DateTime.now();
    if (_lastDetectionTime != null &&
        now.difference(_lastDetectionTime!).inMilliseconds <
            _detectionIntervalMs) {
      return;
    }

    _isDetecting = true;
    _lastDetectionTime = now;

    try {
      // Store camera image size for coordinate conversion
      _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Convert camera image to InputImage with error handling
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        developer.log("⚠️ Failed to convert camera image");
        return;
      }

      // Process with pose detector
      final poses = await _poseDetector!.processImage(inputImage);

      // Update wrist detection with smoothing
      _updateWristDetection(poses);
    } catch (e) {
      developer.log("❌ Error processing camera image: $e");
      // Reset detection state on error
      setState(() {
        _wristDetected = false;
        _wristPosition = null;
      });
    } finally {
      _isDetecting = false;
    }
  }

  /// Convert CameraImage to InputImage with better error handling
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);

      if (rotation == null) {
        developer.log("⚠️ Unknown rotation value: ${camera.sensorOrientation}");
        return null;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        developer.log("⚠️ Unknown image format: ${image.format.raw}");
        return null;
      }

      if (image.planes.isEmpty) {
        developer.log("⚠️ Image has no planes");
        return null;
      }

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      developer.log("❌ Error converting camera image: $e");
      return null;
    }
  }

  /// Enhanced wrist detection with better filtering and multiple wrist checking
  void _updateWristDetection(List<Pose> poses) {
    bool wristFound = false;
    Offset? detectedWristPosition;
    double bestConfidence = 0.0;
    String detectedWrist = "";

    for (final pose in poses) {
      // Check both wrists and pick the one with highest confidence
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

      // Check right wrist
      if (rightWrist != null && rightWrist.likelihood > _minConfidence) {
        if (rightWrist.likelihood > bestConfidence) {
          wristFound = true;
          detectedWristPosition = Offset(rightWrist.x, rightWrist.y);
          bestConfidence = rightWrist.likelihood;
          detectedWrist = "Right";
        }
      }

      // Check left wrist
      if (leftWrist != null && leftWrist.likelihood > _minConfidence) {
        if (leftWrist.likelihood > bestConfidence) {
          wristFound = true;
          detectedWristPosition = Offset(leftWrist.x, leftWrist.y);
          bestConfidence = leftWrist.likelihood;
          detectedWrist = "Left";
        }
      }

      // Also check for hand landmarks as backup (sometimes more reliable)
      final rightIndex = pose.landmarks[PoseLandmarkType.rightIndex];
      final leftIndex = pose.landmarks[PoseLandmarkType.leftIndex];

      if (!wristFound) {
        // Use hand index as wrist approximation if wrist not detected
        if (rightIndex != null && rightIndex.likelihood > _minConfidence) {
          if (rightIndex.likelihood > bestConfidence) {
            wristFound = true;
            // Approximate wrist position from index finger
            detectedWristPosition =
                Offset(rightIndex.x + 20, rightIndex.y + 30);
            bestConfidence = rightIndex.likelihood;
            detectedWrist = "Right (from hand)";
          }
        }

        if (leftIndex != null && leftIndex.likelihood > _minConfidence) {
          if (leftIndex.likelihood > bestConfidence) {
            wristFound = true;
            // Approximate wrist position from index finger
            detectedWristPosition = Offset(leftIndex.x - 20, leftIndex.y + 30);
            bestConfidence = leftIndex.likelihood;
            detectedWrist = "Left (from hand)";
          }
        }
      }
    }

    if (wristFound && detectedWristPosition != null) {
      // Add to recent positions for smoothing
      _recentWristPositions.add(detectedWristPosition);
      if (_recentWristPositions.length > _maxRecentPositions) {
        _recentWristPositions.removeAt(0);
      }

      _consecutiveDetections++;

      // Show watch after consecutive detections
      if (_consecutiveDetections >= _minConsecutiveDetections) {
        // Calculate smoothed position
        Offset smoothedPosition = _calculateSmoothedPosition();

        setState(() {
          _wristDetected = true;
          _wristPosition = smoothedPosition;
        });

        developer.log(
            "✅ $detectedWrist wrist detected at (${smoothedPosition.dx.toInt()}, ${smoothedPosition.dy.toInt()}) with confidence ${(bestConfidence * 100).toInt()}%");
      }
    } else {
      _consecutiveDetections = 0;
      _recentWristPositions.clear();

      setState(() {
        _wristDetected = false;
        _wristPosition = null;
      });

      developer.log("❌ No wrist detected or confidence too low");
    }
  }

  /// Calculate smoothed position from recent detections
  Offset _calculateSmoothedPosition() {
    if (_recentWristPositions.isEmpty) return Offset.zero;

    double totalX = 0;
    double totalY = 0;

    // Give more weight to recent positions
    for (int i = 0; i < _recentWristPositions.length; i++) {
      double weight =
          (i + 1) / _recentWristPositions.length; // More recent = higher weight
      totalX += _recentWristPositions[i].dx * weight;
      totalY += _recentWristPositions[i].dy * weight;
    }

    double weightSum = 0;
    for (int i = 1; i <= _recentWristPositions.length; i++) {
      weightSum += i / _recentWristPositions.length;
    }

    return Offset(totalX / weightSum, totalY / weightSum);
  }

  Future<void> _flipCamera() async {
    _initializeCamera(!_isUsingFrontCamera);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture the AR screen
      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // Save to gallery
        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(pngBytes),
          quality: 100,
          name: "AR_Watch_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['isSuccess']
                  ? 'AR photo saved!'
                  : 'Failed to save photo'),
              backgroundColor: result['isSuccess'] ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      developer.log("❌ Error capturing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture AR photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isCapturing = false;
    });
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Try On: ${widget.productTitle}",
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    // Show error message if there is one
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading indicator while initializing
    if (_isInitializing ||
        _isImageLoading ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Loading AR watch...",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Camera view with watch overlay
    return RepaintBoundary(
      key: _globalKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_cameraController!),

          // Watch overlay - Show when wrist is detected with real-time position
          if (!_isImageLoading && _watchImage != null && _wristDetected)
            CustomPaint(
              painter: _wristPosition != null && _cameraImageSize != null
                  ? WristWatchPainter(
                      watchImage: _watchImage!,
                      screenSize: MediaQuery.of(context).size,
                      isFrontCamera: _isUsingFrontCamera,
                      widthScale: _widthScale,
                      heightScale: _heightScale,
                      wristPosition: _wristPosition!,
                      cameraSize: _cameraImageSize!,
                    )
                  : SimpleWatchPainter(
                      watchImage: _watchImage!,
                      screenSize: MediaQuery.of(context).size,
                      isFrontCamera: _isUsingFrontCamera,
                      widthScale: _widthScale,
                      heightScale: _heightScale,
                    ),
              child: Container(),
            ),

          // Status indicator - Show wrist detection status
          if (!_isImageLoading && !_isCapturing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_wristDetected ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _wristDetected
                      ? "✅ Watch Active - Tracking Your Wrist!"
                      : _consecutiveDetections > 0
                          ? "🔄 Detecting... (${_consecutiveDetections}/${_minConsecutiveDetections})"
                          : "🤚 Position your wrist in view to try on the watch",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Simple size adjustment controls like sunglasses
          if (_showSizeControls && !_isCapturing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Width adjustment
                    Row(
                      children: [
                        const Icon(Icons.width_normal,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('Width:',
                            style: TextStyle(color: Colors.white)),
                        Expanded(
                          child: Slider(
                            value: _widthScale,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey,
                            label: _widthScale.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                _widthScale = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Height adjustment
                    Row(
                      children: [
                        const Icon(Icons.height, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('Height:',
                            style: TextStyle(color: Colors.white)),
                        Expanded(
                          child: Slider(
                            value: _heightScale,
                            min: 0.5,
                            max: 2.0,
                            divisions: 30,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey,
                            label: _heightScale.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                _heightScale = value;
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

          // Bottom camera controls
          if (!_isCapturing)
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
                        onPressed: _flipCamera,
                      ),
                    ),

                    // Capture button
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.black, size: 35),
                        onPressed: _captureImage,
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

          // Capture overlay
          if (_isCapturing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
