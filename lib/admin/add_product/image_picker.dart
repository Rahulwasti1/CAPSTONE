// import 'dart:io';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class ImagePickerWidget extends StatefulWidget {
//   final List<XFile> imageFiles;
//   final Function(List<XFile>) onImagesSelected; // Callback for selected images

//   const ImagePickerWidget({
//     super.key,
//     required this.imageFiles,
//     required this.onImagesSelected,
//   });

//   @override
//   State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
// }

// class _ImagePickerWidgetState extends State<ImagePickerWidget> {
//   final ImagePicker _picker = ImagePicker();
//   List<XFile> _images = [];

//   @override
//   void initState() {
//     super.initState();
//     _images = widget.imageFiles; // Initialize with existing images
//   }

//   Future<void> _pickImages() async {
//     final List<XFile>? pickedFiles = await _picker.pickMultiImage();
//     if (pickedFiles != null) {
//       setState(() {
//         _images.addAll(pickedFiles); // Add picked images to the list
//       });
//       widget.onImagesSelected(_images); // Send back to parent
//     }
//   }

//   void _removeImage(int index) {
//     setState(() {
//       _images.removeAt(index); // Remove selected image
//     });
//     widget.onImagesSelected(_images); // Update parent with new list
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _pickImages,
//       child: DottedBorder(
//         color: Colors.blue,
//         strokeWidth: 1,
//         borderType: BorderType.RRect,
//         radius: Radius.circular(10),
//         child: Container(
//           height: 100,
//           width: double.infinity,
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: Colors.blue.shade100,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 15),
//             child: Wrap(
//               children: [
//                 Column(
//                   children: [
//                     Icon(Icons.add_a_photo, color: Colors.blue),
//                     Text("Select Images",
//                         style: TextStyle(fontWeight: FontWeight.w500)),
//                     if (_images.isNotEmpty)
//                       GridView.builder(
//                         shrinkWrap: true,
//                         itemCount: _images.length,
//                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 3,
//                           crossAxisSpacing: 5,
//                           mainAxisSpacing: 5,
//                         ),
//                         itemBuilder: (context, index) {
//                           return Stack(
//                             fit: StackFit.expand,
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   File(_images[index].path),
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               Positioned(
//                                 top: 5,
//                                 right: 5,
//                                 child: GestureDetector(
//                                   onTap: () => _removeImage(index),
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.red,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     padding: EdgeInsets.all(4),
//                                     child: Icon(Icons.close,
//                                         color: Colors.white, size: 16),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         },
//                       ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
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
    // Show dialog about image size and limits
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Image Selection Guidelines"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please follow these guidelines for best results:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("• Select smaller images (under 1MB each)"),
            Text("• Maximum 5 images per product"),
            Text("• Square or portrait images work best"),
            Text("• Avoid very large or high-resolution images"),
            SizedBox(height: 10),
            Text(
              "Large images will be automatically resized, but may affect upload speed.",
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Now pick images
              final List<XFile>? pickedFiles = await _picker.pickMultiImage();
              if (pickedFiles != null && pickedFiles.isNotEmpty) {
                // Check each image size and warn if too large
                bool anyLargeImages = false;
                for (var image in pickedFiles) {
                  final fileSize = await image.length();
                  if (fileSize > 1 * 1024 * 1024) {
                    // 1MB
                    anyLargeImages = true;
                    break;
                  }
                }

                // Calculate how many images we can add (limit to 5)
                final int totalImagesCount =
                    _images.length + pickedFiles.length;
                final List<XFile> imagesToAdd;

                if (totalImagesCount > 5) {
                  // If we'll exceed 5 images, only add enough to reach 5
                  final int availableSlots = 5 - _images.length;
                  imagesToAdd = pickedFiles.take(availableSlots).toList();

                  // Warn that we limited the images
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Only added ${imagesToAdd.length} images. Maximum 5 images per product."),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  imagesToAdd = pickedFiles;
                }

                setState(() {
                  _images.addAll(imagesToAdd);
                });
                widget.onImagesSelected(_images);

                // Warn about large images if needed
                if (anyLargeImages) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Some images are large and will be resized for better performance."),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: Text("SELECT IMAGES"),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index); // Remove selected image
    });
    widget.onImagesSelected(_images); // Update parent with new list
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Product Images",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              " *",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: DottedBorder(
            color: Colors.blue,
            strokeWidth: 1,
            borderType: BorderType.RRect,
            radius: Radius.circular(10),
            child: Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    "Select Images",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 20), // Spacing between the button and the images

        // Selected Images Grid
        if (_images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(), // Disable grid scrolling
            itemCount: _images.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Number of columns in the grid
              crossAxisSpacing: 5, // Spacing between columns
              mainAxisSpacing: 5, // Spacing between rows
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
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
