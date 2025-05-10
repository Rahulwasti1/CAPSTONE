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
import 'package:capstone/screens/ar/asset_watches_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ARWatchesScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productImage;
  final String productTitle;
  final String productId;

  const ARWatchesScreen({
    super.key,
    required this.cameras,
    required this.productImage,
    required this.productTitle,
    required this.productId,
  });

  @override
  State<ARWatchesScreen> createState() => _ARWatchesScreenState();
}

class _ARWatchesScreenState extends State<ARWatchesScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  List<Face> _faces = [];
  bool _isUsingFrontCamera = true;
  Size? _imageSize;
  bool _isInitializing = true;
  String? _errorMessage;
  ui.Image? _watchImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  bool _isForceCaptureMode =
      false; // Special mode for capturing without indicators
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // Size and position adjustment values
  double _widthScale = 1.5; // Increased default width scale for watches
  double _heightScale = 1.0; // Default height scale for watches
  double _horizontalOffset =
      0.9; // Increased horizontal offset for better wrist positioning
  double _verticalOffset =
      0.75; // Default vertical position (percentage of screen height)
  bool _showAdjustmentControls = true; // Show adjustment controls by default
  bool _useLeftWrist = false; // Option to switch between left and right wrist
  bool _showTooltip = true; // Show initial usage tooltip

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    _loadWatchImage();
    _initializeCamera(true); // Start with front camera

    // Always show controls by default to help with positioning
    _showAdjustmentControls = true;

    // Auto-hide tooltip after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }
    });

    // Show a message instructing users to position their wrist and adjust controls
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Position your wrist in camera and use sliders to adjust watch placement",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  Future<void> _loadWatchImage() async {
    try {
      setState(() {
        _isImageLoading = true;
        _errorMessage = null; // Clear any previous errors
      });

      developer.log("============================================");
      developer.log("🔍 LOADING WATCH IMAGE");
      developer.log("Product Title: '${widget.productTitle}'");
      developer.log("Product ID: '${widget.productId}'");
      developer.log("============================================");

      // Get product title and ID for matching
      final String lowerTitle = widget.productTitle.toLowerCase();
      final String lowerId = widget.productId.toLowerCase();

      // Determine which watch image to use based on product information
      String imagePath;

      // PRECISE MATCHING: Use exact product information to select the correct watch model
      if (lowerTitle.contains('diesel') ||
          lowerTitle.contains('mega chief') ||
          lowerId.contains('diesel') ||
          lowerTitle.contains('chief')) {
        // Load Diesel watch
        imagePath = 'assets/effects/watches/Diesel Mega Chief.png';
        developer.log(
            "Selected Diesel Mega Chief watch based on product information");
      } else if (lowerTitle.contains('guess') ||
          lowerTitle.contains('letterm') ||
          lowerId.contains('guess') ||
          lowerTitle.contains('letter')) {
        // Load Guess watch
        imagePath = 'assets/effects/watches/Guess Letterm.png';
        developer
            .log("Selected Guess Letterm watch based on product information");
      } else {
        // Alternate watches based on product ID to ensure different watches appear
        // If no specific match, use product ID hash to alternate between available watches
        final int productHash = widget.productId.hashCode.abs();
        final bool useFirstWatch =
            productHash % 2 == 0; // Even hashes get first watch

        if (useFirstWatch) {
          imagePath = 'assets/effects/watches/Diesel Mega Chief.png';
          developer
              .log("Selected Diesel watch based on product ID hash (even)");
        } else {
          imagePath = 'assets/effects/watches/Guess Letterm.png';
          developer.log("Selected Guess watch based on product ID hash (odd)");
        }
      }

      developer.log("Loading watch image: $imagePath");

      // Try to load the selected image with error handling
      try {
        final ByteData data = await rootBundle.load(imagePath);
        if (data.lengthInBytes == 0) {
          throw Exception("Image data is empty");
        }

        developer.log("Image data loaded, bytes: ${data.lengthInBytes}");
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo fi = await codec.getNextFrame();

        if (!mounted) return;

        if (fi.image.width == 0 || fi.image.height == 0) {
          throw Exception("Image dimensions invalid");
        }

        developer.log(
            "Image decoded successfully: ${fi.image.width}x${fi.image.height}");

        setState(() {
          _watchImage = fi.image;
          _isImageLoading = false;
        });

        developer.log("Successfully loaded watch image: $imagePath");
        return;
      } catch (e) {
        developer.log("!!! ERROR loading image: ${e.toString()}");

        // Try alternative watch as fallback
        try {
          developer.log("Trying alternative watch image");
          // Use the other watch model as fallback
          final alternativePath = imagePath.contains("Diesel")
              ? 'assets/effects/watches/Guess Letterm.png'
              : 'assets/effects/watches/Diesel Mega Chief.png';

          final ByteData alternativeData =
              await rootBundle.load(alternativePath);
          final Uint8List alternativeBytes =
              alternativeData.buffer.asUint8List();
          final ui.Codec alternativeCodec =
              await ui.instantiateImageCodec(alternativeBytes);
          final ui.FrameInfo alternativeFi =
              await alternativeCodec.getNextFrame();

          if (!mounted) return;

          setState(() {
            _watchImage = alternativeFi.image;
            _isImageLoading = false;
          });

          developer.log("Successfully loaded alternative watch image");
          return;
        } catch (alternativeError) {
          developer.log("Alternative image also failed: $alternativeError");
          // Continue to placeholder as last resort
        }
      }

      // List all assets for debugging
      try {
        final manifestContent = await DefaultAssetBundle.of(context)
            .loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        final watchAssets = manifestMap.keys
            .where((String key) => key.contains('watches/'))
            .toList();
        developer.log("Available watch assets:");
        for (var asset in watchAssets) {
          developer.log("  $asset");
        }
      } catch (e) {
        developer.log("Error listing assets: $e");
      }

      // If we get here, create a placeholder image as last resort
      await _createPlaceholderImage();

      if (!mounted) return;
      setState(() {
        _isImageLoading = false;
      });
    } catch (e) {
      developer.log("Failed to load watch image: $e");
      if (!mounted) return;

      // Try to create a placeholder as last resort
      await _createPlaceholderImage();

      if (!mounted) return;
      setState(() {
        _isImageLoading = false;
        _errorMessage =
            "Failed to load watch image. Try adjusting size and position.";
      });
      _showWatchImageAlert();
    }
  }

  // Show alert to user that image loading failed but they can try controls
  void _showWatchImageAlert() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Watch image couldn't be loaded. Try the controls to adjust placement.",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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

  void _toggleWristSide() {
    setState(() {
      _useLeftWrist = !_useLeftWrist;
      _horizontalOffset = -_horizontalOffset; // Flip the horizontal offset
    });
  }

  Future<void> _captureAndSaveImage() async {
    if (_isCapturing || !_cameraActive) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // 1. Hide ALL UI elements before capturing
      final bool wasShowingControls = _showAdjustmentControls;
      final bool wasShowingTooltip = _showTooltip;
      final bool wasShowingLoading = _isImageLoading;

      // Completely hide UI elements including the capture indicator itself
      setState(() {
        _showAdjustmentControls = false;
        _showTooltip = false;
        _isImageLoading = false;
        _isForceCaptureMode = true; // Enter special capture mode
      });

      // 2. Essential: Wait for UI to update completely with longer delay
      await Future.delayed(const Duration(milliseconds: 1200));

      // 3. Stop camera stream for clean capture
      bool wasStreaming = false;
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          _cameraController!.value.isStreamingImages) {
        wasStreaming = true;
        await _cameraController!.stopImageStream();
      }

      // 4. Additional delay for clean frame
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Capture the screen with highest quality
      RenderRepaintBoundary? boundary = _globalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Failed to find the repaint boundary");
      }

      // Capture at maximum resolution
      ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 6. Save to gallery with meaningful name
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name:
            "Watch_${widget.productTitle.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}",
      );

      // 7. Wait before showing success and restoring UI
      await Future.delayed(const Duration(milliseconds: 300));

      // 8. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image saved to gallery"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 9. Restore UI state
      if (mounted) {
        setState(() {
          _showAdjustmentControls = wasShowingControls;
          _showTooltip = wasShowingTooltip;
          _isImageLoading = wasShowingLoading;
          _isForceCaptureMode = false; // Exit force capture mode
        });
      }

      // 10. Restart camera
      if (mounted &&
          wasStreaming &&
          _cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.isStreamingImages &&
          _cameraActive) {
        try {
          await _cameraController!.startImageStream(_processCameraImage);
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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // Always ensure we exit all special modes
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isForceCaptureMode =
              false; // Always ensure we exit force capture mode
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
                "Loading AR watch...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Camera view with face detection overlay
    return Stack(
      children: [
        // Main content in RepaintBoundary for clean capture
        RepaintBoundary(
          key: _globalKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              CameraPreview(_cameraController!),

              // IMPORTANT: Only show loading overlay during image loading, not when camera is ready
              // Also don't show during image capture or force capture mode
              if (_isImageLoading && !_isCapturing && !_isForceCaptureMode)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text("Loading watch image...",
                            style: TextStyle(color: Colors.white))
                      ],
                    ),
                  ),
                ),

              // Face overlay with watch - ALWAYS show the watch even if no faces detected
              // ONLY SHOW WHEN IMAGE IS LOADED - Prevent the placeholder from showing
              if (!_isImageLoading && _watchImage != null)
                CustomPaint(
                  painter: AssetWatchesPainter(
                    faces: _faces.isEmpty
                        ? [
                            Face(
                              boundingBox:
                                  Rect.fromLTWH(0, 0, 100, 100), // Dummy face
                              landmarks: {},
                              contours: {},
                              trackingId: 1,
                            )
                          ]
                        : _faces,
                    imageSize:
                        _imageSize ?? Size(100, 100), // Provide default size
                    screenSize: MediaQuery.of(context).size,
                    cameraLensDirection:
                        _cameraController!.description.lensDirection,
                    showWatch: true,
                    watchImage: _watchImage,
                    widthScale: _widthScale,
                    heightScale: _heightScale,
                    horizontalOffset: _useLeftWrist
                        ? -_horizontalOffset.abs()
                        : _horizontalOffset.abs(),
                    verticalOffset: _verticalOffset,
                    stabilizePosition: true,
                  ),
                ),

              // Show initial tooltip for watch positioning
              if (_showTooltip &&
                  !_isImageLoading &&
                  !_isCapturing &&
                  !_isForceCaptureMode)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Position your arm in frame and use the adjustment controls to resize and reposition the watch",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showTooltip = false;
                              _showAdjustmentControls = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text("Show Controls"),
                        ),
                      ],
                    ),
                  ),
                ),

              // Adjustment controls
              if (_showAdjustmentControls &&
                  !_isCapturing &&
                  !_isImageLoading &&
                  !_isForceCaptureMode)
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
                            const Text('Size:',
                                style: TextStyle(color: Colors.white)),
                            Expanded(
                              child: Slider(
                                value: _widthScale,
                                min: 0.8,
                                max: 3.0, // Increased max size
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

                        // Position adjustment (horizontal)
                        Row(
                          children: [
                            const Icon(Icons.horizontal_distribute,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text('Distance:',
                                style: TextStyle(color: Colors.white)),
                            Expanded(
                              child: Slider(
                                value: _horizontalOffset.abs(),
                                min: 0.3,
                                max:
                                    3.0, // Increased max distance to cover more of the hand
                                divisions: 27,
                                activeColor: Colors.blue,
                                inactiveColor: Colors.grey,
                                label:
                                    _horizontalOffset.abs().toStringAsFixed(1),
                                onChanged: (value) {
                                  setState(() {
                                    _horizontalOffset =
                                        _useLeftWrist ? -value : value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        // Vertical position adjustment
                        Row(
                          children: [
                            const Icon(Icons.vertical_align_center,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text('Height:',
                                style: TextStyle(color: Colors.white)),
                            Expanded(
                              child: Slider(
                                value: _verticalOffset,
                                min: 0.5, // Higher in the screen
                                max: 0.9, // Lower in the screen
                                divisions: 20,
                                activeColor: Colors.blue,
                                inactiveColor: Colors.grey,
                                label:
                                    (_verticalOffset * 100).toStringAsFixed(0) +
                                        "%",
                                onChanged: (value) {
                                  setState(() {
                                    _verticalOffset = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        // Wrist selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Wrist:',
                                style: TextStyle(color: Colors.white)),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('Left'),
                              selected: _useLeftWrist,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _useLeftWrist = true;
                                    _horizontalOffset =
                                        -_horizontalOffset.abs();
                                  });
                                }
                              },
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(
                                color:
                                    _useLeftWrist ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('Right'),
                              selected: !_useLeftWrist,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _useLeftWrist = false;
                                    _horizontalOffset = _horizontalOffset.abs();
                                  });
                                }
                              },
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(
                                color: !_useLeftWrist
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom controls
              if (!_isCapturing && !_isImageLoading && !_isForceCaptureMode)
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
            ],
          ),
        ),

        // Capture overlay - OUTSIDE the RepaintBoundary so it doesn't appear in saved images
        if (_isCapturing && !_isForceCaptureMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: Container(
              color: Colors.black.withAlpha(120),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Saving image...",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _createPlaceholderImage() async {
    // Create a simple colored placeholder
    try {
      developer.log("Creating placeholder image as last resort");

      // Create a canvas to draw the placeholder
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = const Size(200, 200);

      // Draw a watch shape
      final paint = Paint()
        ..color = Colors.grey.shade800
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      // Draw the watch face
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 20,
        paint,
      );

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 20,
        borderPaint,
      );

      // Convert to image
      final picture = pictureRecorder.endRecording();
      final img =
          await picture.toImage(size.width.toInt(), size.height.toInt());

      // Set as watch image
      if (mounted) {
        setState(() {
          _watchImage = img;
          _errorMessage = null;
        });
      }

      developer.log("Created placeholder image successfully");
    } catch (e) {
      developer.log("Failed to create placeholder image: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Failed to load any watch image. Please try another product.";
        });
      }
    }
  }
}
