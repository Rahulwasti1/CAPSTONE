import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:developer' as developer;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String title;
  final String category;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.title,
    required this.category,
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
  String? _errorMessage;

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

      // Save image to gallery
      await ImageGallerySaver.saveFile(image.path);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
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
