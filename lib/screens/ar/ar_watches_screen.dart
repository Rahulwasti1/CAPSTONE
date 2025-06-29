import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';

import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:capstone/screens/ar/asset_watches_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:capstone/service/asset_organizer_service.dart';
import 'package:http/http.dart' as http;

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
  bool _isUsingFrontCamera = false; // DEFAULT: Back camera for realistic AR
  String? _errorMessage;
  ui.Image? _watchImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();

  // Simple size controls like sunglasses - START BIG so users can reduce
  double _widthScale = 1.5;
  double _heightScale = 1.5;
  bool _showSizeControls = false;

  // Wrist detection variables - forgiving for production use
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  bool _wristDetected = false;
  int _consecutiveDetections = 0;
  static const int _minConsecutiveDetections = 2; // Restored to working value
  static const double _minConfidence = 0.5; // Restored to working range

  // Detection timing
  DateTime? _lastDetectionTime;
  static const int _detectionIntervalMs = 100; // Faster detection

  // Detection status for user feedback
  String _detectionStatus = "Hold your wrist steady in camera view 📱";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePoseDetector();
    _loadWatchImage();
    _initializeCamera(false);
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

      ui.Image? loadedImage;

      // Priority 1: Try organized document storage
      loadedImage = await _tryLoadFromDocumentStorage();
      if (loadedImage != null) {
        setState(() {
          _watchImage = loadedImage;
          _isImageLoading = false;
        });
        return;
      }

      // Priority 2: Try loading from Firebase images (base64)
      if (widget.productImage.isNotEmpty) {
        loadedImage = await _tryLoadFromFirebaseImages();
        if (loadedImage != null) {
          setState(() {
            _watchImage = loadedImage;
            _isImageLoading = false;
          });
          return;
        }
      }

      // Priority 3: Try loading from product-specific assets
      loadedImage = await _tryLoadFromProductAssets();
      if (loadedImage != null) {
        setState(() {
          _watchImage = loadedImage;
          _isImageLoading = false;
        });
        return;
      }

      // Priority 4: Try generic assets with smart selection
      loadedImage = await _tryLoadFromGenericAssets();
      if (loadedImage != null) {
        setState(() {
          _watchImage = loadedImage;
          _isImageLoading = false;
        });
        return;
      }

      // Create placeholder if all else fails
      await _createPlaceholderImage();
      setState(() {
        _isImageLoading = false;
      });
    } catch (e) {
      await _createPlaceholderImage();
      setState(() {
        _isImageLoading = false;
        _errorMessage = "Failed to load watch image";
      });
    }
  }

  Future<ui.Image?> _tryLoadFromFirebaseImages() async {
    try {
      if (widget.productImage.isEmpty) return null;

      // Handle base64 image data
      if (widget.productImage.contains('base64,')) {
        String base64Image = widget.productImage.split('base64,')[1];
        final bytes = base64Decode(base64Image);
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();
        return fi.image;
      }

      // Handle network URLs
      if (widget.productImage.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.productImage));
        if (response.statusCode == 200) {
          final ui.Codec codec =
              await ui.instantiateImageCodec(response.bodyBytes);
          final ui.FrameInfo fi = await codec.getNextFrame();
          return fi.image;
        }
      }

      return null;
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

  Future<ui.Image?> _tryLoadFromDocumentStorage() async {
    try {
      List<File> documentImages = await AssetOrganizerService.getProductImages(
        category: 'Watches',
        productId: widget.productId,
        productTitle: widget.productTitle,
        selectedColor: null,
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
            // Failed to load document watch image
            continue;
          }
        }
      }
    } catch (e) {
      // Failed to load from document storage
    }

    return null;
  }

  Future<ui.Image?> _tryLoadFromGenericAssets() async {
    try {
      final String lowerTitle = widget.productTitle.toLowerCase();
      String imagePath;

      // Available watch assets
      final Map<String, String> availableWatches = {
        'diesel': 'assets/effects/watches/Diesel Mega Chief.png',
        'mega chief': 'assets/effects/watches/Diesel Mega Chief.png',
        'guess': 'assets/effects/watches/Guess Letterm.png',
        'letterm': 'assets/effects/watches/Guess Letterm.png',
        'nixon': 'assets/effects/watches/Nixon-Gold.png',
        'sport': 'assets/effects/watches/SportTrouer-Green.png'
      };

      // Smart matching logic
      for (var entry in availableWatches.entries) {
        if (lowerTitle.contains(entry.key)) {
          imagePath = entry.value;

          final ByteData data = await rootBundle.load(imagePath);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();
          return fi.image;
        }
      }

      // Default to first available watch if no match found
      imagePath = availableWatches.values.first;

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

      // Start image stream for pose detection
      controller.startImageStream(_processCameraImage);

      setState(() {
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera error: ${e.description}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera';
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraController != null) {
      try {
        // Stop image stream before disposing
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
      } catch (e) {
        // Ignore any errors during disposal
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
      // Convert camera image to InputImage with error handling
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        return;
      }

      // Process with pose detector
      final poses = await _poseDetector!.processImage(inputImage);

      // Update wrist detection
      _updateWristDetection(poses);
    } catch (e) {
      // Reset detection state on error
      setState(() {
        _wristDetected = false;
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
        return null;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        return null;
      }

      if (image.planes.isEmpty) {
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
      return null;
    }
  }

  /// Simplified wrist detection with user-friendly feedback
  void _updateWristDetection(List<Pose> poses) {
    bool validWristFound = false;
    double bestConfidence = 0.0;

    // Update status based on pose detection
    if (poses.isEmpty) {
      setState(() {
        _wristDetected = false;
        _detectionStatus = "Hold your wrist steady in camera view 📱";
      });
      _consecutiveDetections = 0;
      return;
    }

    for (final pose in poses) {
      // Get wrist landmarks with simpler validation
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

      // Check right wrist with forgiving thresholds
      if (rightWrist != null && rightWrist.likelihood > _minConfidence) {
        if (rightWrist.likelihood > bestConfidence) {
          validWristFound = true;
          bestConfidence = rightWrist.likelihood;
        }
      }

      // Check left wrist with forgiving thresholds
      if (leftWrist != null && leftWrist.likelihood > _minConfidence) {
        if (leftWrist.likelihood > bestConfidence) {
          validWristFound = true;
          bestConfidence = leftWrist.likelihood;
        }
      }
    }

    if (validWristFound) {
      _consecutiveDetections++;

      // Update status to show progress
      setState(() {
        if (_consecutiveDetections >= _minConsecutiveDetections) {
          _wristDetected = true;
          _detectionStatus = "Perfect wrist detection! ⌚️";
        } else {
          _detectionStatus = "Detecting wrist... Keep steady! ⏳";
        }
      });
    } else {
      _consecutiveDetections = 0;
      setState(() {
        _wristDetected = false;
        _detectionStatus = "Hold your wrist steady in camera view 📱";
      });
    }
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

          // Watch overlay - Show when wrist is detected
          if (!_isImageLoading && _watchImage != null && _wristDetected)
            CustomPaint(
              size: Size.infinite,
              painter: WristWatchPainter(
                watchImage: _watchImage!,
                screenSize: MediaQuery.of(context).size,
                isFrontCamera: _isUsingFrontCamera,
                widthScale: _widthScale,
                heightScale: _heightScale,
                wristDetected: _wristDetected,
              ),
            ),

          // Detection status indicator - always show
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _wristDetected
                    ? Colors.green.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_wristDetected)
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20)
                  else
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _detectionStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
