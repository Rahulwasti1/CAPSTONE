import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final List<XFile> imageFiles;
  final Function(List<XFile>) onImagesSelected; // Callback for selected images

  const ImagePickerWidget({
    super.key,
    required this.imageFiles,
    required this.onImagesSelected,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _images = widget.imageFiles; // Initialize with existing images
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles); // Add picked images to the list
      });
      widget.onImagesSelected(_images); // Send back to parent
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index); // Remove selected image
    });
    widget.onImagesSelected(_images); // Update parent with new list
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(Icons.add_a_photo, color: Colors.blue),
            Text("Select Images",
                style: TextStyle(fontWeight: FontWeight.w500)),
            if (_images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                itemCount: _images.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_images[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
