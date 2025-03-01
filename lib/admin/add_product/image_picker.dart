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
    return Column(
      children: [
        // "Select Images" Section
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
