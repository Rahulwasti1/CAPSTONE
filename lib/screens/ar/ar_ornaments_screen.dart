import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:ui' as ui;
import 'dart:async'; // For Completer
import 'dart:convert'; // For base64Decode and json
import 'package:capstone/screens/ar/asset_ornaments_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class AROrnamentScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productImage;
  final String productTitle;
  final String productId;

  const AROrnamentScreen({
    super.key,
    required this.cameras,
    required this.productImage,
    required this.productTitle,
    required this.productId,
  });

  @override
  State<AROrnamentScreen> createState() => _AROrnamentScreenState();
}

class _AROrnamentScreenState extends State<AROrnamentScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  List<Face> _faces = [];
  bool _isUsingFrontCamera = true;
  Size? _imageSize;
  bool _isInitializing = true;
  String? _errorMessage;
  final String _assetImagePath = 'assets/effects/ornaments/necklace.png';
  ui.Image? _ornamentImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // Size and position adjustment values
  double _widthScale = 2.0; // Default width scale
  double _heightScale = 1.2; // Default height scale - taller for necklaces
  double _verticalOffset =
      0.5; // Increased default vertical offset for lower position
  bool _showAdjustmentControls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    _testOrnamentImages(); // Test all paths first
    _loadOrnamentImage();
    _initializeCamera(true); // Start with front camera
  }

  Future<void> _loadOrnamentImage() async {
    try {
      setState(() {
        _isImageLoading = true;
        _errorMessage = null; // Clear any previous errors
      });

      developer.log("============================================");
      developer.log("🔍 LOADING ORNAMENT IMAGE");
      developer.log("Product Title: '${widget.productTitle}'");
      developer.log("Product ID: '${widget.productId}'");
      developer.log("============================================");

      // Declare lowerTitle at the top for use throughout the method
      final String lowerTitle = widget.productTitle.toLowerCase();

      // DIRECT MAPPING - Find the exact image file to use
      String imagePath;

      // Watch products - use watches folder
      if (lowerTitle.contains('watch') ||
          lowerTitle.contains('diesel') ||
          lowerTitle.contains('guess')) {
        // Check for specific watch models
        if (lowerTitle.contains('diesel') ||
            lowerTitle.contains('mega chief')) {
          imagePath = 'assets/effects/watches/Diesel Mega Chief.png';
        } else if (lowerTitle.contains('guess') ||
            lowerTitle.contains('letterm')) {
          imagePath = 'assets/effects/watches/Guess Letterm.png';
        } else {
          // Default watch
          imagePath = 'assets/effects/watches/Diesel Mega Chief.png';
        }
        developer.log("Using watch image: $imagePath");
      }
      // Chain/necklace products
      else if (lowerTitle.contains('chain') ||
          lowerTitle.contains('necklace') ||
          lowerTitle.contains('bke')) {
        imagePath = 'assets/effects/ornament/BKEChain.png';
        developer.log("Using chain image: $imagePath");
      }
      // Cross products
      else if (lowerTitle.contains('cross') || lowerTitle.contains('pendant')) {
        imagePath = 'assets/effects/ornament/Cross-black.png';
        developer.log("Using cross image: $imagePath");
      }
      // Default fallback
      else {
        // Try to guess based on product name
        if (widget.productTitle.contains("Cross")) {
          imagePath = 'assets/effects/ornament/Cross-black.png';
        } else {
          imagePath = 'assets/effects/ornament/BKEChain.png';
        }
        developer.log("Using default image: $imagePath");
      }

      try {
        developer.log("Loading image: $imagePath");
        final ByteData data = await rootBundle.load(imagePath);
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();

        if (!mounted) return;

        setState(() {
          _ornamentImage = fi.image;
          _isImageLoading = false;
        });

        developer.log("Successfully loaded image: $imagePath");
        return;
      } catch (e) {
        developer.log("Failed to load image: ${e.toString()}");
        // Fall through to fallback method
      }

      // If we get here, try to load default image
      try {
        await _loadDefaultImage();
      } catch (e) {
        developer.log("Failed to load default ornament image: $e");
        // Try creating a placeholder image as last resort
        await _createPlaceholderImage();
      }

      if (!mounted) return;

      // Only set _isImageLoading to false if we haven't already set an error message
      if (_errorMessage == null) {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      developer.log("Failed to load ornament image: $e");
      if (!mounted) return;

      // Try to create a placeholder as last resort
      await _createPlaceholderImage();

      if (!mounted) return;
      setState(() {
        _isImageLoading = false;
        if (_ornamentImage == null) {
          _errorMessage = "Failed to load ornament image: $e";
        }
      });
    }
  }

  Future<void> _loadDefaultImage() async {
    // Log available assets for debugging
    developer.log("Available ornament assets:");
    developer.log(" - Product title: ${widget.productTitle}");
    developer.log(" - Product ID: ${widget.productId}");

    // Declare lowerTitle at the top for use throughout the method
    final String lowerTitle = widget.productTitle.toLowerCase();

    // Track if we've tried any image paths at all
    bool attemptedAnyPath = false;
    List<String> failedPaths = [];

    // Exact match by filename
    final String productName = widget.productTitle.replaceAll(' ', '-');
    final List<String> possibleImageNames = [
      // Exact match by filename
      'assets/effects/ornament/${productName}.png',
      'assets/effects/ornament/${widget.productId}.png',

      // Try exact file names we know exist based on product title
      if (widget.productTitle.toLowerCase().contains("cross"))
        'assets/effects/ornament/Cross-black.png',
      if (widget.productTitle.toLowerCase().contains("chain") ||
          widget.productTitle.toLowerCase().contains("necklace") ||
          widget.productTitle.toLowerCase().contains("bke"))
        'assets/effects/ornament/BKEChain.png',

      // More variations of the product name
      'assets/effects/ornament/${productName.toLowerCase()}.png',
      'assets/effects/ornament/${productName.toUpperCase()}.png',

      // Always fallback to available images for testing
      'assets/effects/ornament/Cross-black.png',
      'assets/effects/ornament/BKEChain.png',
    ];

    developer.log("Trying ${possibleImageNames.length} possible image paths");

    // Try each possible image name
    for (final imagePath in possibleImageNames) {
      attemptedAnyPath = true;
      try {
        developer.log("Trying image path: $imagePath");
        final ByteData data = await rootBundle.load(imagePath);
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();

        if (!mounted) return;

        setState(() {
          _ornamentImage = fi.image;
        });

        developer.log("Successfully loaded ornament image: $imagePath");
        return; // Successfully loaded an image, so exit
      } catch (e) {
        failedPaths.add(imagePath);
        // Just continue to the next possible image
      }
    }

    // If we get here and didn't try any paths, it's a configuration error
    if (!attemptedAnyPath) {
      throw Exception("No image paths were attempted - check configuration");
    }

    // If we get here and tried all paths, throw descriptive error
    throw Exception(
        "Failed to load any ornament image. Tried paths: ${failedPaths.join(', ')}");
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableTracking: true,
      enableClassification: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initializeCamera(bool useFrontCamera) async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    // Dispose of previous controller if it exists
    await _disposeCurrentCamera();

    if (widget.cameras.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = "No cameras available";
      });
      return;
    }

    try {
      // Find the requested camera
      CameraDescription selectedCamera;

      if (useFrontCamera) {
        // Look specifically for a front camera
        try {
          selectedCamera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );
        } catch (e) {
          // Fall back to the first camera if no front camera
          developer.log("No front camera found, using first camera");
          selectedCamera = widget.cameras.first;
        }
      } else {
        // Look specifically for a back camera
        try {
          selectedCamera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );
        } catch (e) {
          // Fall back to the first camera if no back camera
          developer.log("No back camera found, using first camera");
          selectedCamera = widget.cameras.first;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      _cameraController = controller;

      // Initialize controller
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Set camera parameters and start stream with proper error handling
      try {
        if (Platform.isAndroid) {
          await controller.setZoomLevel(1.0);
          await controller.setExposureMode(ExposureMode.auto);
          await controller.setExposureOffset(0.0);
          await controller.setFocusMode(FocusMode.auto);
          await controller.startImageStream(_processCameraImage);
        } else {
          await controller.setExposureMode(ExposureMode.auto);
          await controller.setExposureOffset(0.0);
          await controller.setFocusMode(FocusMode.auto);
          await controller.setFlashMode(FlashMode.off);
          await controller.startImageStream(_processCameraImage);
        }

        _isUsingFrontCamera = useFrontCamera;
        _cameraActive = true;
      } catch (e) {
        developer.log("Error configuring camera stream: $e");
        // If we can't start the stream, we still want to show the camera preview
        // so we don't set an error message here
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
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
        if (_cameraController!.value.isInitialized) {
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
          }
          await _cameraController!.dispose();
        }
      } on CameraException catch (e) {
        developer.log(
            "Camera exception during disposal: ${e.code}: ${e.description}");
      } catch (e) {
        developer.log("Error disposing camera: $e");
      }
      _cameraController = null;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !_cameraActive) return;
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isBusy = false;
      return;
    }

    try {
      final faces = await _faceDetector?.processImage(inputImage);
      if (mounted && faces != null && _cameraActive) {
        setState(() {
          _faces = faces;
          _imageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
        });
      }
    } catch (e) {
      developer.log("Error processing image: $e");
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null || !_cameraActive) return null;

    try {
      // Get camera rotation
      final camera = _cameraController!.description;
      final imageRotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      // Get image format
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final bytes = _concatenatePlanes(image.planes);

      // Updated to use the current API
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      developer.log("Error creating input image: $e");
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void _toggleCamera() {
    _initializeCamera(!_isUsingFrontCamera);
  }

  void _toggleAdjustmentControls() {
    setState(() {
      _showAdjustmentControls = !_showAdjustmentControls;
    });
  }

  Future<void> _captureAndSaveImage() async {
    if (_isCapturing || !_cameraActive) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Safely pause camera stream
      bool wasStreaming = false;
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          _cameraController!.value.isStreamingImages) {
        wasStreaming = true;
        try {
          await _cameraController!.stopImageStream();
        } on CameraException catch (e) {
          developer.log(
              "Camera exception stopping stream: ${e.code}: ${e.description}");
        } catch (e) {
          developer.log("Error stopping camera stream: $e");
        }
      }

      // Hide the controls for the screenshot
      setState(() {
        _showAdjustmentControls = false;
      });

      // Allow the UI to update before capturing
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the screen
      RenderRepaintBoundary? boundary = _globalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Failed to find the repaint boundary");
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to gallery
      await ImageGallerySaver.saveImage(pngBytes,
          quality: 100,
          name:
              "AR_${widget.productTitle}_${DateTime.now().millisecondsSinceEpoch}");

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image saved to gallery"),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Restart the camera stream if it was running before
      if (mounted &&
          wasStreaming &&
          _cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.isStreamingImages &&
          _cameraActive) {
        try {
          await _cameraController!.startImageStream(_processCameraImage);
        } on CameraException catch (e) {
          developer.log(
              "Camera exception restarting stream: ${e.code}: ${e.description}");
        } catch (e) {
          developer.log("Error restarting camera stream: $e");
        }
      }
    } catch (e) {
      developer.log("Error capturing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save image: ${e.toString()}"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCurrentCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (!_cameraActive) {
        _initializeCamera(_isUsingFrontCamera);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentCamera();
    _faceDetector?.close();
    super.dispose();
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
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                "Loading AR ornament...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Camera view with face detection overlay
    return RepaintBoundary(
      key: _globalKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_cameraController!),

          // Face overlay with ornament
          if (_faces.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: AssetOrnamentsPainter(
                faces: _faces,
                imageSize: _imageSize!,
                screenSize: MediaQuery.of(context).size,
                cameraLensDirection:
                    _cameraController!.description.lensDirection,
                showOrnament: true,
                ornamentImage: _ornamentImage,
                widthScale: _widthScale,
                heightScale: _heightScale,
                verticalOffset: _verticalOffset,
                stabilizePosition: true,
              ),
            ),

          // Adjustment controls
          if (_showAdjustmentControls && !_isCapturing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withAlpha(138),
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
                            min: 1.0,
                            max: 3.5,
                            divisions: 25,
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
                            max: 2.5,
                            divisions: 20,
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

                    // Position adjustment
                    Row(
                      children: [
                        const Icon(Icons.vertical_align_bottom,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('Position:',
                            style: TextStyle(color: Colors.white)),
                        Expanded(
                          child: Slider(
                            value: _verticalOffset,
                            min: 0.1,
                            max: 1.5, // Increased maximum vertical offset
                            divisions:
                                28, // Increased divisions for finer control
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey,
                            label: _verticalOffset.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                _verticalOffset = value;
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

          // Bottom controls
          if (!_isCapturing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withAlpha(138),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera toggle button
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: widget.cameras.length > 1 && !_isInitializing
                            ? _toggleCamera
                            : null,
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
                        onPressed: _captureAndSaveImage,
                      ),
                    ),

                    // Adjustment button
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _showAdjustmentControls
                          ? Colors.blue.withAlpha(153)
                          : Colors.black38,
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleAdjustmentControls,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Capture overlay
          if (_isCapturing)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Debug method to test all possible image paths
  Future<void> _testOrnamentImages() async {
    developer.log("===== TESTING ALL POSSIBLE ORNAMENT IMAGES =====");
    developer.log("Product Title: ${widget.productTitle}");
    developer.log("Product ID: ${widget.productId}");

    final String productName = widget.productTitle.replaceAll(' ', '-');
    final List<String> testPaths = [
      'assets/effects/ornament/Cross-black.png',
      'assets/effects/ornament/BKEChain.png',
      'assets/effects/ornament/${productName}.png',
      'assets/effects/ornament/${widget.productId}.png',
      'assets/effects/ornament/${productName.toLowerCase()}.png',
      _assetImagePath,
    ];

    for (final path in testPaths) {
      try {
        await rootBundle.load(path);
        developer.log("SUCCESS: Image exists at path: $path");
      } catch (e) {
        developer.log("ERROR: Image does not exist at path: $path");
      }
    }
    developer.log("===============================================");
  }

  Future<void> _createPlaceholderImage() async {
    // Create a simple colored placeholder
    try {
      developer.log("Creating placeholder image as last resort");

      // Create a canvas to draw the placeholder
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = const Size(200, 300);

      // Draw a cross shape
      final paint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      // Vertical line
      canvas.drawLine(Offset(size.width / 2, 50),
          Offset(size.width / 2, size.height - 50), paint);

      // Horizontal line
      canvas.drawLine(Offset(50, size.height / 3),
          Offset(size.width - 50, size.height / 3), paint);

      // Convert to image
      final picture = pictureRecorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());

      // Set as ornament image
      if (mounted) {
        setState(() {
          _ornamentImage = img;
          _errorMessage = null;
        });
      }

      developer.log("Created placeholder image successfully");
    } catch (e) {
      developer.log("Failed to create placeholder image: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Failed to load any ornament image. Please try another product.";
        });
      }
    }
  }
}
