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
  bool _isBusy = false;
  List<Face> _faces = [];
  bool _isUsingFrontCamera = true;
  Size? _imageSize;
  bool _isInitializing = true;
  String? _errorMessage;
  final String _assetImagePath = 'assets/effects/apparel/tshirt_default.png';
  ui.Image? _tshirtImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // Size and position adjustment values
  double _widthScale = 3.0; // Default width scale
  double _heightScale = 1.5; // Default height scale for t-shirts
  double _verticalOffset = 0.6; // How far down from face to place the t-shirt
  bool _showAdjustmentControls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    _testImagePaths(); // Test all paths first
    _loadTshirtImage();
    _initializeCamera(true); // Start with front camera
  }

  // Debug method to test all possible image paths
  Future<void> _testImagePaths() async {
    developer.log("===== TESTING ALL POSSIBLE T-SHIRT IMAGES =====");
    developer.log("Product Title: ${widget.productTitle}");
    developer.log("Product ID: ${widget.productId}");

    final List<String> testPaths = [
      'assets/effects/ornament/Cross-black.png',
      'assets/effects/ornament/BKEChain.png',
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

    // Test direct matches
    final String lowerTitle = widget.productTitle.toLowerCase();
    final List<String> keywords = [
      'cross',
      'chain',
      'necklace',
      'bke',
      'premium',
      'pendant'
    ];

    for (final keyword in keywords) {
      if (lowerTitle.contains(keyword)) {
        developer.log("KEYWORD MATCH: Product title contains '$keyword'");
      }
    }

    developer.log("===============================================");
  }

  Future<void> _loadTshirtImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      developer.log("============================================");
      developer.log("🔍 LOADING T-SHIRT IMAGE");
      developer.log("Product Title: '${widget.productTitle}'");
      developer.log("Product ID: '${widget.productId}'");
      developer.log("============================================");

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
          imagePath = _assetImagePath; // Default t-shirt
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
          _tshirtImage = fi.image;
          _isImageLoading = false;
        });

        developer.log("Successfully loaded image: $imagePath");
        return;
      } catch (e) {
        developer.log("Failed to load image: ${e.toString()}");
        // Fall through to fallback method
      }

      // Log which product we're trying to load an image for
      developer.log("Continuing with regular approach for: $lowerTitle");

      // Check for specific product types in the title for better matching
      bool isCross = lowerTitle.contains('cross');
      bool isChain =
          lowerTitle.contains('chain') || lowerTitle.contains('necklace');

      developer
          .log("Product type detection: isCross=$isCross, isChain=$isChain");

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
        if (exactMatch != null) {
          developer.log("Found exact match in mapping: $exactMatch");
        }

        // If no exact match, check for keyword match
        if (exactMatch == null) {
          // Sort keys by length (descending) to prioritize more specific matches
          final sortedKeys = ornamentMapping.keys.toList()
            ..sort((a, b) => b.length.compareTo(a.length));

          for (final key in sortedKeys) {
            if (lowerTitle.contains(key)) {
              exactMatch = ornamentMapping[key] as String;
              developer.log(
                  "Keyword match found in ornaments: '$key' -> $exactMatch");
              break;
            }
          }
        }

        // If not found in ornaments, check tshirts mapping
        if (exactMatch == null) {
          final Map<String, dynamic> tshirtMapping =
              mapping['tshirts'] as Map<String, dynamic>;
          exactMatch = tshirtMapping['default'] as String?;
          developer.log("Using default t-shirt: $exactMatch");
        }

        // If we found a match, load that image
        if (exactMatch != null) {
          try {
            developer.log("Loading mapped image: $exactMatch");
            final ByteData data = await rootBundle.load(exactMatch);
            final Uint8List bytes = data.buffer.asUint8List();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo fi = await codec.getNextFrame();

            if (!mounted) return;

            setState(() {
              _tshirtImage = fi.image;
              _isImageLoading = false;
            });

            developer
                .log("Successfully loaded mapped product image: $exactMatch");
            return;
          } catch (e) {
            developer
                .log("Failed to load mapped product image: ${e.toString()}");
            // Fall through to next approach
          }
        }
      } catch (e) {
        developer.log("Failed to load product mapping: ${e.toString()}");
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
            developer.log("DIRECT MATCH! Trying to load: ${entry.value}");
            final ByteData data = await rootBundle.load(entry.value);
            final Uint8List bytes = data.buffer.asUint8List();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo fi = await codec.getNextFrame();

            if (!mounted) return;

            setState(() {
              _tshirtImage = fi.image;
              _isImageLoading = false;
            });

            developer.log(
                "Successfully loaded specific product image: ${entry.value}");
            return;
          } catch (e) {
            developer.log("Failed to load matched image: ${e.toString()}");
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
            developer.log("Failed to load network image: $exception");
            _loadDefaultImage();
          }));

          // Wait for the image to load with a timeout
          _tshirtImage = await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              developer
                  .log("Network image loading timed out, using default image");
              _loadDefaultImage();
              throw TimeoutException('Image loading timed out');
            },
          );

          if (_tshirtImage != null) {
            developer.log("Network t-shirt image loaded successfully");
          }
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

            developer.log("Base64 t-shirt image loaded successfully");
          } catch (e) {
            developer.log("Failed to load base64 image: $e");
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
      developer.log("Failed to load t-shirt image: $e");
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

      developer.log(
          "Trying to load product image for: ${widget.productTitle} (ID: ${widget.productId})");

      // Try each possible image name
      for (final imagePath in possibleImageNames) {
        try {
          developer.log("Trying image path: $imagePath");
          final ByteData data = await rootBundle.load(imagePath);
          final Uint8List bytes = data.buffer.asUint8List();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();

          if (!mounted) return;

          setState(() {
            _tshirtImage = fi.image;
          });

          developer.log("Successfully loaded product image: $imagePath");
          return; // Successfully loaded an image, so exit
        } catch (e) {
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

            developer.log("Loaded ornament image as fallback: $imagePath");
            return; // Successfully loaded an image, so exit
          } catch (e) {
            // Continue to try next image
          }
        }
      } catch (e) {
        developer.log("Error loading from ornament folder: $e");
      }

      // Fall back to default t-shirt placeholder
      final ByteData data = await rootBundle.load(_assetImagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      if (!mounted) return;

      setState(() {
        _tshirtImage = fi.image;
      });

      developer.log("Default t-shirt image loaded successfully");
    } catch (e) {
      developer.log("Failed to load any t-shirt image: $e");
    }
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
        ResolutionPreset.medium,
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
          await controller.startImageStream(_processCameraImage);
        } else {
          await controller.setExposureMode(ExposureMode.auto);
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

    // Camera view with face detection overlay
    return RepaintBoundary(
      key: _globalKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_cameraController!),

          // Face overlay with t-shirt
          if (_faces.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: AssetTshirtPainter(
                faces: _faces,
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
                            min: 2.0,
                            max: 5.0,
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
                            min: 1.0,
                            max: 3.0,
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
                            min: 0.3,
                            max: 1.5,
                            divisions: 20,
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
}
