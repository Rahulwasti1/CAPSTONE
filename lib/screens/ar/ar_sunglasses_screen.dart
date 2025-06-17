import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:capstone/screens/ar/asset_sunglasses_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:capstone/service/asset_organizer_service.dart';

class ARSunglassesScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productImage;
  final String productTitle;
  final String? productId;
  final Map<String, dynamic>? productData;

  const ARSunglassesScreen({
    super.key,
    required this.cameras,
    required this.productImage,
    required this.productTitle,
    this.productId,
    this.productData,
  });

  @override
  State<ARSunglassesScreen> createState() => _ARSunglassesScreenState();
}

class _ARSunglassesScreenState extends State<ARSunglassesScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  List<Face> _faces = [];
  bool _isUsingFrontCamera = true;
  Size? _imageSize;
  bool _isInitializing = true;
  String? _errorMessage;
  final String _assetImagePath = 'assets/effects/glasses/blueglass.png';
  ui.Image? _glassesImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // Size adjustment values
  double _widthScale = 3.5; // Default width scale
  double _heightScale = 0.4; // Default height scale
  bool _showSizeControls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    _loadGlassesImage();
    _initializeCamera(true); // Start with front camera
  }

  Future<void> _loadGlassesImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      ui.Image? loadedImage;

      // Priority 1: Try organized document storage
      loadedImage = await _tryLoadFromDocumentStorage();
      if (loadedImage != null) {
        setState(() {
          _glassesImage = loadedImage;
          _isImageLoading = false;
        });
        developer.log("✅ Loaded sunglasses from document storage");
        return;
      }

      // Priority 2: Try loading from Firebase images (base64)
      if (widget.productData != null) {
        loadedImage = await _tryLoadFromFirebaseImages();
        if (loadedImage != null) {
          setState(() {
            _glassesImage = loadedImage;
            _isImageLoading = false;
          });
          developer.log("✅ Loaded sunglasses from Firebase images");
          return;
        }
      }

      // Priority 3: Try generic assets
      final ByteData data = await rootBundle.load(_assetImagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      if (!mounted) return;

      setState(() {
        _glassesImage = fi.image;
        _isImageLoading = false;
      });

      developer.log("✅ Loaded sunglasses from generic assets");
    } catch (e) {
      developer.log("Failed to load glasses image: $e");
      if (!mounted) return;

      setState(() {
        _isImageLoading = false;
        _errorMessage = "Failed to load glasses image: $e";
      });
    }
  }

  Future<ui.Image?> _tryLoadFromDocumentStorage() async {
    try {
      List<File> documentImages = await AssetOrganizerService.getProductImages(
        category: 'Sunglasses',
        productId: widget.productId ??
            widget
                .productTitle, // Use productId if available, fallback to title
        productTitle: widget.productTitle,
        selectedColor: null,
      );

      if (documentImages.isNotEmpty) {
        developer.log(
            '🎯 Found ${documentImages.length} organized sunglasses images');

        // Try to load the first matching image
        for (File imageFile in documentImages) {
          try {
            final bytes = await imageFile.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            developer
                .log('📸 Loaded organized sunglasses image: ${imageFile.path}');
            return frame.image;
          } catch (e) {
            developer.log(
                '❌ Failed to load document sunglasses image: ${imageFile.path} - $e');
            continue;
          }
        }
      }
    } catch (e) {
      developer.log('⚠️ Error loading sunglasses from document storage: $e');
    }

    return null;
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
      developer.log("Failed to load Firebase sunglasses image: $e");
      return null;
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
      // Finding the requested camera
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

      // Setting camera parameters and start stream with proper error handling
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
      // Converting the frames to ML Kit Format
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

  void _toggleSizeControls() {
    setState(() {
      _showSizeControls = !_showSizeControls;
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
        _showSizeControls = false;
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
                "Loading AR glasses...",
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

          // Face overlay
          if (_faces.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: AssetSunglassesPainter(
                faces: _faces,
                imageSize: _imageSize!,
                screenSize: MediaQuery.of(context).size,
                cameraLensDirection:
                    _cameraController!.description.lensDirection,
                showSunglasses: true,
                assetImagePath: _assetImagePath,
                glassesImage: _glassesImage,
                widthScale: _widthScale,
                heightScale: _heightScale,
                stabilizePosition: true,
              ),
            ),

          // Size adjustment controls
          if (_showSizeControls && !_isCapturing)
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
                            min: 0.2,
                            max: 0.6,
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
                  ],
                ),
              ),
            ),

          // Bottom controls - SIMPLIFIED to just 3 buttons
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

                    // Size adjustment button
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _showSizeControls
                          ? Colors.blue.withAlpha(153)
                          : Colors.black38,
                      child: IconButton(
                        icon: const Icon(
                          Icons.straighten,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleSizeControls,
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
