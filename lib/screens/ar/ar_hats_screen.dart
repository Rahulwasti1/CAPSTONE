import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:capstone/screens/ar/asset_hats_painter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:capstone/service/asset_organizer_service.dart';

class ARHatsScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String productImage;
  final String productTitle;
  final String? productId;
  final Map<String, dynamic>? productData;

  const ARHatsScreen({
    super.key,
    required this.cameras,
    required this.productImage,
    required this.productTitle,
    this.productId,
    this.productData,
  });

  @override
  State<ARHatsScreen> createState() => _ARHatsScreenState();
}

class _ARHatsScreenState extends State<ARHatsScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  List<Face> _faces = [];
  bool _isUsingFrontCamera = false;
  Size? _imageSize;
  bool _isInitializing = true;
  String? _errorMessage;
  final String _assetImagePath = 'assets/effects/hats/hats.png';
  ui.Image? _hatImage;
  bool _isImageLoading = true;
  bool _isCapturing = false;
  final GlobalKey _globalKey = GlobalKey();
  bool _cameraActive = false;

  // Size adjustment values for realistic hat fitting - FIXED SCALING
  double _widthScale = 1.2; // Slightly larger to ensure full hair coverage
  double _heightScale = 1.2; // Larger height to cover more of the head
  double _verticalOffset =
      -0.15; // Position hat closer to head, just above forehead
  bool _showSizeControls = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFaceDetector();
    _loadHatImage();
    _initializeCamera(
        false); // Start with back camera for realistic AR experience
  }

  Future<void> _loadHatImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      ui.Image? loadedImage;

      // Priority 1: Try organized document storage
      loadedImage = await _tryLoadFromDocumentStorage();
      if (loadedImage != null) {
        setState(() {
          _hatImage = loadedImage;
          _isImageLoading = false;
        });
        return;
      }

      // Priority 2: Try loading from Firebase images (base64)
      if (widget.productData != null) {
        loadedImage = await _tryLoadFromFirebaseImages();
        if (loadedImage != null) {
          setState(() {
            _hatImage = loadedImage;
            _isImageLoading = false;
          });
          return;
        }
      }

      // Priority 3: Use default hat asset
      final ByteData data = await rootBundle.load(_assetImagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();

      if (!mounted) return;

      setState(() {
        _hatImage = fi.image;
        _isImageLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isImageLoading = false;
        _errorMessage = "Failed to load hat image: $e";
      });
    }
  }

  Future<ui.Image?> _tryLoadFromDocumentStorage() async {
    try {
      List<File> documentImages = await AssetOrganizerService.getProductImages(
        category: 'Hats',
        productId: widget.productId ?? widget.productTitle,
        productTitle: widget.productTitle,
        selectedColor: null,
      );

      if (documentImages.isNotEmpty) {
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
    } catch (e) {
      // Continue to fallback options
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
      return null;
    }
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableTracking: true,
      enableClassification: true,
      minFaceSize: 0.15, // Slightly larger for better head detection
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

    await _disposeCurrentCamera();

    if (widget.cameras.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = "No cameras available";
      });
      return;
    }

    final camera = useFrontCamera
        ? widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => widget.cameras.first)
        : widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => widget.cameras.first);

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _isUsingFrontCamera = useFrontCamera;
        _cameraActive = true;
      });

      if (!_cameraController!.value.isStreamingImages) {
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = "Failed to initialize camera: $e";
      });
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraController != null) {
      _cameraActive = false;
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isBusy || !mounted) return;

    _isBusy = true;

    final inputImage = _convertCameraImage(image);
    if (inputImage != null) {
      _detectFaces(inputImage);
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
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

  Future<void> _detectFaces(InputImage inputImage) async {
    try {
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _faces = faces;
        _imageSize = inputImage.metadata?.size;
      });
    } catch (e) {
      // Handle detection errors silently
    } finally {
      _isBusy = false;
    }
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
    if (_isCapturing || _cameraController == null) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture the current widget as an image
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery
      await ImageGallerySaver.saveImage(pngBytes,
          name: "hat_tryOn_${DateTime.now().millisecondsSinceEpoch}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hat try-on photo saved to gallery!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    if (state == AppLifecycleState.paused) {
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
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Try On: ${widget.productTitle}",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                "Loading AR hat...",
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

          // Face overlay with hat
          if (_faces.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: AssetHatsPainter(
                faces: _faces,
                imageSize: _imageSize!,
                screenSize: MediaQuery.of(context).size,
                cameraLensDirection:
                    _cameraController!.description.lensDirection,
                showHat: true,
                hatImage: _hatImage,
                widthScale: _widthScale,
                heightScale: _heightScale,
                verticalOffset: _verticalOffset,
                stabilizePosition: true,
              ),
            ),

          // Size adjustment controls
          if (_showSizeControls)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height * 0.15,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hat Size',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Width control - Fixed range to prevent shrinking
                    const Text('Width',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: _widthScale,
                        min: 0.8,
                        max: 1.4,
                        divisions: 12,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          setState(() {
                            _widthScale = value;
                          });
                        },
                      ),
                    ),

                    // Height control - Fixed range for natural proportions
                    const Text('Height',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: _heightScale,
                        min: 0.8,
                        max: 1.4,
                        divisions: 12,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          setState(() {
                            _heightScale = value;
                          });
                        },
                      ),
                    ),

                    // Position control - Fixed range for head top positioning
                    const Text('Position',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: _verticalOffset,
                        min: -0.5,
                        max: 0.1,
                        divisions: 12,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          setState(() {
                            _verticalOffset = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Status indicator at top
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _faces.isNotEmpty
                    ? Colors.green.withOpacity(0.8)
                    : Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _faces.isNotEmpty
                    ? 'Perfect face detection! 🎩 Adjust hat size with controls below'
                    : 'Position your face in the camera view 📱',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera toggle button
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleCamera,
                    ),
                  ),

                  // Capture photo button
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera,
                              color: Colors.black,
                              size: 32,
                            ),
                      onPressed: _isCapturing ? null : _captureAndSaveImage,
                    ),
                  ),

                  // Size adjustment toggle button
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _showSizeControls
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(
                        Icons.tune,
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
        ],
      ),
    );
  }
}
