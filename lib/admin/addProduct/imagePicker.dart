import 'package:flutter/material.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';
import 'package:image_picker/image_picker.dart';

class Imagepicker extends StatefulWidget {
  const Imagepicker({super.key});

  @override
  State<Imagepicker> createState() => _ImagepickerState();
}

class _ImagepickerState extends State<Imagepicker> {
  final ImagePicker _picker = ImagePicker();
  final controller = MultiImagePickerController(
    maxImages: 10,
    images: <ImageFile>[],
    picker: (bool allowMultiple) async {
      return await pickConvertedImages(allowMultiple);
    },
  );

  /// Function to pick images from gallery
  static Future<List<ImageFile>> pickConvertedImages(bool allowMultiple) async {
    final ImagePicker picker = ImagePicker();
    List<XFile>? pickedFiles;

    if (allowMultiple) {
      pickedFiles = await picker.pickMultiImage();
    } else {
      final XFile? singleImage =
          await picker.pickImage(source: ImageSource.gallery);
      if (singleImage != null) {
        pickedFiles = [singleImage];
      }
    }

    if (pickedFiles == null) {
      return [];
    }

    // Convert XFile to ImageFile (used by MultiImagePickerView)
    // Convert XFile to ImageFile with name and extension
    List<ImageFile> imageFiles = pickedFiles.map((file) {
      // Get file name and extension
      String fileName = file.name;
      String fileExtension = fileName.split('.').last;

      return ImageFile(
        file.path, // Path to the image file
        name: fileName, // File name
        extension: fileExtension, // File extension
      );
    }).toList();

    return imageFiles;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: EdgeInsets.all(10),
      child: MultiImagePickerView(
        controller: controller,
      ),
    );
  }
}
