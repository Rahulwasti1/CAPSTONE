import 'package:dotted_border/dotted_border.dart';
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
    maxImages: 5,
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

    // Converting XFile to ImageFile with name and extension
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
    return Wrap(children: [
      Padding(
          padding: EdgeInsets.zero,
          child: DottedBorder(
            radius: Radius.circular(10),
            color: Color.fromARGB(255, 195, 229, 236),
            borderType: BorderType.RRect, // round border
            dashPattern: const [6, 3],
            child: // thickness and number of line), ),
                Container(
              decoration: BoxDecoration(
                  color: Color(0xFFcde7ec),
                  borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.all(10),
              child: MultiImagePickerView(
                controller: controller,
              ),
            ),
          )),
    ]);
  }
}
