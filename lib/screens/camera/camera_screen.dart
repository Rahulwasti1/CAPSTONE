import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:developer' as developer;
import 'package:capstone/service/virtual_try_on_service.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String title;
  final String category;
  final String productImageBase64; // Base64 of the product image

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.title,
    required this.category,
    required this.productImageBase64,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;
  bool _isUsingFrontCamera = false;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _processedImageBase64;
  final VirtualTryOnService _apiService = VirtualTryOnService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize the back camera by default
    _initCamera(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;

    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_isUsingFrontCamera);
    }
  }

  Future<void> _initCamera(bool useFrontCamera) async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    // Dispose of previous controller if it exists
    await _disposeCurrentCamera();

    // Log available cameras for debugging
    developer.log("Available cameras: ${widget.cameras.length}");
    for (var i = 0; i < widget.cameras.length; i++) {
      developer.log(
          "Camera $i: ${widget.cameras[i].name}, ${widget.cameras[i].lensDirection}");
    }

    if (widget.cameras.isEmpty) {
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

      developer.log(
          "Selected camera: ${selectedCamera.name}, ${selectedCamera.lensDirection}");

      // Initialize the controller with medium resolution for better performance
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium, // Lower resolution for faster loading
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      // Set up controller future with timeout for initialization
      _initializeControllerFuture = controller.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Camera initialization timed out');
        },
      );

      // Wait for controller to initialize
      await _initializeControllerFuture;

      _isUsingFrontCamera = useFrontCamera;

      if (mounted) {
        setState(() {
          _isInitializing = false;
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
    if (_controller != null) {
      try {
        if (_controller!.value.isInitialized) {
          await _controller!.dispose();
        }
      } catch (e) {
        developer.log("Error disposing camera: $e");
      }
      _controller = null;
    }
  }

  void _toggleCamera() {
    // Toggle between front and back camera
    _initCamera(!_isUsingFrontCamera);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentCamera();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture ||
        _controller == null ||
        !_controller!.value.isInitialized) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final image = await _controller!.takePicture();

      // Process the image with the virtual try-on service
      await _processWithVirtualTryOn(image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _processWithVirtualTryOn(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _processedImageBase64 = null;
      _errorMessage = null;
    });

    try {
      // Read the image file
      final File file = File(imagePath);
      final List<int> imageBytes = await file.readAsBytes();

      // Convert to base64
      final String faceImageBase64 = base64Encode(imageBytes);

      // Use the product image base64 passed from the product detail screen
      final String glassesImageBase64 = widget.productImageBase64;

      // Check if the product is in sunglasses category
      if (widget.category.toLowerCase() != 'sunglasses' &&
          widget.category.toLowerCase() != 'eyewear') {
        throw Exception(
            'Virtual try-on is only available for sunglasses category');
      }

      // Step 1: Set the sunglasses image first
      final bool glassesSet =
          await _apiService.setSunglasses(glassesImageBase64);

      if (!glassesSet) {
        throw Exception('Failed to set sunglasses image');
      }

      developer.log('Sunglasses set successfully, now applying to face');

      // Step 2: Apply the sunglasses to the face image
      final String? resultImageBase64 =
          await _apiService.applySunglasses(faceImageBase64);

      if (resultImageBase64 != null) {
        // Save the processed image
        await _saveProcessedImage(resultImageBase64);

        // Update the UI
        if (mounted) {
          setState(() {
            _processedImageBase64 = resultImageBase64;
            _isProcessing = false;
          });
        }
      } else {
        throw Exception('Failed to process the image');
      }
    } catch (e) {
      developer.log('Error in virtual try-on: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to process try-on: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Virtual try-on failed: $e')),
        );
      }
    }
  }

  Future<void> _saveProcessedImage(String base64Image) async {
    try {
      // Decode base64 to bytes
      final List<int> imageBytes = base64Decode(base64Image);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create a temporary file
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File tempFile =
          File('${tempDir.path}/virtual_tryon_$timestamp.jpg');

      // Write to the file
      await tempFile.writeAsBytes(imageBytes);

      // Save to gallery
      await ImageGallerySaver.saveFile(tempFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Try-on image saved to gallery')),
        );
      }
    } catch (e) {
      developer.log('Error saving processed image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
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

    // Show processed image if available
    if (_processedImageBase64 != null) {
      return Stack(
        children: [
          // Display the processed image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.memory(
              base64Decode(_processedImageBase64!),
              fit: BoxFit.contain,
            ),
          ),

          // Bottom controls for the processed image
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Back to camera button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _processedImageBase64 = null;
                      });
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('New Try-On'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),

                  // Done button (return to product)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show loading indicator while processing
    if (_isProcessing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Processing virtual try-on...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading indicator while initializing
    if (_isInitializing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    // Show camera preview when ready
    return Stack(
      children: [
        // Fullscreen camera preview
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_controller!),
        ),

        // Bottom controls overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Switch camera button
                CircleAvatar(
                  radius: 25,
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

                // Camera shutter button
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      _isTakingPicture
                          ? Icons.hourglass_full
                          : Icons.camera_alt,
                      size: 40,
                      color: Colors.black,
                    ),
                    onPressed: _isTakingPicture ? null : _takePicture,
                  ),
                ),

                // Placeholder to balance layout
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
