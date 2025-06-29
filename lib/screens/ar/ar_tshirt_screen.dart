import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:capstone/screens/ar/asset_tshirt_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ARTshirtScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productImage;
  final String productTitle;
  final String productId;

  const ARTshirtScreen({
    super.key,
    required this.cameras,
    required this.productImage,
    required this.productTitle,
    required this.productId,
  });

  @override
  State<ARTshirtScreen> createState() => _ARTshirtScreenState();
}

class _ARTshirtScreenState extends State<ARTshirtScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  List<Face> _faces = [];
  List<Pose> _poses = [];
  bool _isUsingFrontCamera = false; // DEFAULT: Back camera for realistic AR
  Size? _imageSize;
  bool _isInitializing = true;
  String? _errorMessage;
  final String _assetImagePath = 'assets/effects/apparel/tshirt_default.png';
  ui.Image? _tshirtImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // REBUILT: Realistic T-shirt sizing for proper upper body placement
  double _widthScale = 1.2; // Natural width for realistic chest coverage
  double _heightScale = 1.4; // Proper height proportion for upper torso
  double _verticalOffset =
      0.0; // Centered positioning (will be calculated by pose detection)
  bool _showAdjustmentControls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    _initializePoseDetector();
    _loadTshirtImage();
    _initializeCamera(false); // Start with back camera
  }

  Future<void> _loadTshirtImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      // Declare lowerTitle at the top of the method so it's available everywhere
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
      }
      // Chain/necklace products
      else if (lowerTitle.contains('chain') ||
          lowerTitle.contains('necklace') ||
          lowerTitle.contains('bke')) {
        imagePath = 'assets/effects/ornament/BKEChain.png';
      }
      // Cross products
      else if (lowerTitle.contains('cross') || lowerTitle.contains('pendant')) {
        imagePath = 'assets/effects/ornament/Cross-black.png';
      }
      // Default fallback
      else {
        // Try to guess based on product name
        if (widget.productTitle.contains("Cross")) {
          imagePath = 'assets/effects/ornament/Cross-black.png';
        } else {
          imagePath = _assetImagePath; // Default t-shirt
        }
      }

      try {
        final ByteData data = await rootBundle.load(imagePath);
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();

        if (!mounted) return;

        setState(() {
          _tshirtImage = fi.image;
          _isImageLoading = false;
        });

        return;
      } catch (e) {
        // Fall through to fallback method
      }

      // Log which product we're trying to load an image for
      // Check for specific product types in the title for better matching

      // Try to load the product mapping JSON
      try {
        final String mappingJson = await rootBundle
            .loadString('assets/effects/debug/product_images.json');
        final Map<String, dynamic> mapping = json.decode(mappingJson);

        // First check ornament mappings (we want to use the same product image for Try On)
        final Map<String, dynamic> ornamentMapping =
            mapping['ornaments'] as Map<String, dynamic>;

        // Check for exact product name match first
        String? exactMatch = ornamentMapping[lowerTitle] as String?;
        if (exactMatch != null) {}

        // If no exact match, check for keyword match
        if (exactMatch == null) {
          // Sort keys by length (descending) to prioritize more specific matches
          final sortedKeys = ornamentMapping.keys.toList()
            ..sort((a, b) => b.length.compareTo(a.length));

          for (final key in sortedKeys) {
            if (lowerTitle.contains(key)) {
              exactMatch = ornamentMapping[key] as String;
              break;
            }
          }
        }

        // If not found in ornaments, check tshirts mapping
        if (exactMatch == null) {
          final Map<String, dynamic> tshirtMapping =
              mapping['tshirts'] as Map<String, dynamic>;
          exactMatch = tshirtMapping['default'] as String?;
        }

        // If we found a match, load that image
        if (exactMatch != null) {
          try {
            final ByteData data = await rootBundle.load(exactMatch);
            final Uint8List bytes = data.buffer.asUint8List();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo fi = await codec.getNextFrame();

            if (!mounted) return;

            setState(() {
              _tshirtImage = fi.image;
              _isImageLoading = false;
            });

            return;
          } catch (e) {
            // Fall through to next approach
          }
        }
      } catch (e) {
        // Fall through to next approach
      }

      // Direct mapping - fallback if JSON fails
      final Map<String, String> knownProducts = {
        'cross': 'assets/effects/ornament/Cross-black.png',
        'premium cross': 'assets/effects/ornament/Cross-black.png',
        'cross black': 'assets/effects/ornament/Cross-black.png',
        'chain': 'assets/effects/ornament/BKEChain.png',
        'necklace': 'assets/effects/ornament/BKEChain.png',
        'bke chain': 'assets/effects/ornament/BKEChain.png',
        'pendant': 'assets/effects/ornament/Cross-black.png'
      };

      // Check if we have a direct match by product title (case insensitive)
      for (final entry in knownProducts.entries) {
        if (lowerTitle.contains(entry.key)) {
          try {
            final ByteData data = await rootBundle.load(entry.value);
            final Uint8List bytes = data.buffer.asUint8List();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo fi = await codec.getNextFrame();

            if (!mounted) return;

            setState(() {
              _tshirtImage = fi.image;
              _isImageLoading = false;
            });

            return;
          } catch (e) {
            // Continue to next approach
          }
        }
      }

      // If we get here, try using the product image from Firestore
      if (widget.productImage.isNotEmpty) {
        if (widget.productImage.startsWith('http')) {
          // If it's a network URL, fetch and decode
          final NetworkImage networkImage = NetworkImage(widget.productImage);
          final ImageStream imageStream =
              networkImage.resolve(ImageConfiguration.empty);
          final Completer<ui.Image> completer = Completer<ui.Image>();

          imageStream
              .addListener(ImageStreamListener((ImageInfo imageInfo, bool _) {
            completer.complete(imageInfo.image);
          }, onError: (exception, stackTrace) {
            _loadDefaultImage();
          }));

          // Wait for the image to load with a timeout
          _tshirtImage = await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              _loadDefaultImage();
              throw TimeoutException('Image loading timed out');
            },
          );

          if (_tshirtImage != null) {}
        } else if (widget.productImage.contains('base64')) {
          // Handle base64 image
          try {
            String processedImageString = widget.productImage;
            if (processedImageString.contains(',')) {
              processedImageString = processedImageString.split(',')[1];
            }

            final Uint8List bytes = base64Decode(processedImageString);
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo fi = await codec.getNextFrame();
            _tshirtImage = fi.image;
          } catch (e) {
            _loadDefaultImage();
          }
        } else {
          _loadDefaultImage();
        }
      } else {
        _loadDefaultImage();
      }

      // If we reach here, try to load default image
      await _loadDefaultImage();

      if (!mounted) return;

      setState(() {
        _isImageLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isImageLoading = false;
        _errorMessage = "Failed to load t-shirt image: $e";
      });
    }
  }

  Future<void> _loadDefaultImage() async {
    try {
      // First try to load specific product image based on title/ID
      final String productName = widget.productTitle.replaceAll(' ', '-');
      final List<String> possibleImageNames = [
        // Exact match by filename
        'assets/effects/ornament/$productName.png',
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

      // Try each possible image name
      for (final imagePath in possibleImageNames) {
        try {
          final ByteData data = await rootBundle.load(imagePath);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();

          if (!mounted) return;

          setState(() {
            _tshirtImage = fi.image;
          });

          return; // Successfully loaded an image, so exit
        } catch (_) {
          // Just continue to the next possible image
        }
      }

      // If specific product image not found, try generic ornament images
      try {
        // Try each available ornament image
        final ornamentImages = [
          'assets/effects/ornament/Cross-black.png',
          'assets/effects/ornament/BKEChain.png'
        ];

        for (final imagePath in ornamentImages) {
          try {
            final ByteData data = await rootBundle.load(imagePath);
            final Uint8List bytes = data.buffer.asUint8List();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo fi = await codec.getNextFrame();

            if (!mounted) return;

            setState(() {
              _tshirtImage = fi.image;
            });

            return; // Successfully loaded an image, so exit
          } catch (_) {
            // Continue to try next image
          }
        }
      } catch (_) {}

      // Fall back to default t-shirt placeholder
      final ByteData data = await rootBundle.load(_assetImagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      if (!mounted) return;

      setState(() {
        _tshirtImage = fi.image;
      });
    } catch (_) {}
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

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: options);
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
        } catch (_) {
          // Fall back to the first camera if no front camera
          selectedCamera = widget.cameras.first;
        }
      } else {
        // Look specifically for a back camera
        try {
          selectedCamera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );
        } catch (_) {
          // Fall back to the first camera if no back camera
          selectedCamera = widget.cameras.first;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high, // FIXED: Balanced resolution for full body view
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
        // FIXED: Set natural zoom (1x) for full upper body visibility
        await controller.setZoomLevel(1.0); // NO auto-zoom for accurate try-ons
        await controller.setExposureMode(ExposureMode.auto);
        await controller.setExposureOffset(0.0);
        await controller.setFocusMode(FocusMode.auto);
        if (!Platform.isAndroid) {
          await controller.setFlashMode(FlashMode.off);
        }
        await controller.startImageStream(_processCameraImage);

        _isUsingFrontCamera = useFrontCamera;
        _cameraActive = true;
      } catch (_) {
        // If we can't start the stream, we still want to show the camera preview
        // so we don't set an error message here
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = "Camera error: ${e.description}";
        });
      }
    } catch (e) {
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
      } catch (e) {}
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
      // Process both face and pose detection simultaneously
      final futures = await Future.wait([
        _faceDetector?.processImage(inputImage) ?? Future.value(<Face>[]),
        _poseDetector?.processImage(inputImage) ?? Future.value(<Pose>[]),
      ]);

      final faces = futures[0] as List<Face>;
      final poses = futures[1] as List<Pose>;

      if (mounted && _cameraActive) {
        setState(() {
          _faces = faces;
          _poses = poses;
          _imageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
        });
      }
    } catch (e) {
      // Handle detection errors silently
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
        } catch (e) {}
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
        } catch (e) {}
      }
    } catch (e) {
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
    _poseDetector?.close();
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
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
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
                "Loading AR t-shirt...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Camera view with face detection overlay - Fixed white lines
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        color: Colors.black, // Remove white background
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview with full body view
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

            // CRITICAL FIX: T-shirt overlay ABOVE user body layer
            if (_faces.isNotEmpty && _imageSize != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: AssetTshirtPainter(
                    faces: _faces,
                    poses: _poses,
                    imageSize: _imageSize!,
                    screenSize: MediaQuery.of(context).size,
                    cameraLensDirection:
                        _cameraController!.description.lensDirection,
                    showTshirt: true,
                    tshirtImage: _tshirtImage,
                    widthScale: _widthScale,
                    heightScale: _heightScale,
                    verticalOffset: _verticalOffset,
                    stabilizePosition: true,
                  ),
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
                      // Width adjustment - Realistic range for T-shirt
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
                              min: 0.8,
                              max: 2.0,
                              divisions: 24,
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

                      // Height adjustment - Realistic range for T-shirt
                      Row(
                        children: [
                          const Icon(Icons.height,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Height:',
                              style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _heightScale,
                              min: 0.8,
                              max: 2.2,
                              divisions: 28,
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

                      // Position adjustment - Fine-tuning for perfect placement
                      Row(
                        children: [
                          const Icon(Icons.vertical_align_center,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Position:',
                              style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _verticalOffset,
                              min: -0.2,
                              max: 0.2,
                              divisions: 20,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.grey,
                              label: _verticalOffset.toStringAsFixed(2),
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
                          onPressed:
                              widget.cameras.length > 1 && !_isInitializing
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
      ),
    );
  }
}
