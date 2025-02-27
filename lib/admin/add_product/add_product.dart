import 'package:capstone/admin/add_product/categoty_admin.dart';
import 'package:capstone/admin/add_product/image_picker.dart';
import 'package:capstone/admin/add_product/select_color.dart';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/service/adding_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddProduct extends StatefulWidget {
  const AdminAddProduct({
    super.key,
  });

  @override
  State<AdminAddProduct> createState() => _AdminAddProductState();
}

class _AdminAddProductState extends State<AdminAddProduct> {
  final _formKey = GlobalKey<FormState>(); // Form Key for validation
  final AddingProduct _addProduct = AddingProduct();

  bool isLoading = false;

  List<Color> selectedColors = []; // To hold the selected colors
  List<XFile> selectedImages = []; // To store selected images
// Function to add product
  Future<void> _addingProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      // Convert selected colors to a list of strings
      List<String> colorData =
          selectedColors.map((color) => color.value.toString()).toList();

      // Convert price to double
      double price = double.tryParse(priceContorller.text) ?? 0.0;

      // Call addProduct method and pass the selectedImages as List<XFile>
      final result = await _addProduct.addProduct(
        title: titleContorller.text,
        description: descriptionController.text,
        category: categoryContorller.text,
        price: price,
        color: colorData,
        size: sizeContorller.text,
        image: selectedImages, // Ensure you're passing List<XFile>
      );

      setState(() {
        isLoading = false;
      });

      // Show success or error message using a SnackBar
      if (result == "Product added successfully!") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }

      if (result == "Product added successfully!") {
        _formKey.currentState?.reset();
      }
    } else {
      print("Form is not valid");
    }
  }

  // Controller for input fields
  TextEditingController titleContorller = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController categoryContorller = TextEditingController();
  TextEditingController sizeContorller = TextEditingController();
  TextEditingController priceContorller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Form(
          key: _formKey, // Assign the form key here
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: IconButton.styleFrom(
                          side: BorderSide(
                            width: 2.w,
                            color: Color.fromARGB(255, 241, 239, 239),
                          ),
                        ),
                        icon: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 90.w),
                      Text(
                        "Add Product",
                        style: TextStyle(
                            fontSize: 17.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        InputTextField(
                          controller: titleContorller,
                          labelText: "Enter Product Title",
                        ),
                        SizedBox(height: 15.h),
                        InputTextField(
                          controller: descriptionController,
                          labelText: "Enter Product Description",
                        ),
                        SizedBox(height: 15.h),
                        CategotyAdmin(),
                        SizedBox(height: 15.h),
                        SelectAColor(
                          onColorSelected: (colors) {
                            setState(() {
                              selectedColors = colors;
                            });
                          },
                        ),
                        SizedBox(height: 15.h),
                        InputTextField(
                          controller: sizeContorller,
                          labelText: "Enter Size",
                        ),
                        SizedBox(height: 15.h),
                        InputTextField(
                          controller: priceContorller,
                          labelText: "Enter Price",
                        ),
                        SizedBox(height: 20.h),
                        ImagePickerWidget(
                          imageFiles: [],
                          onImagesSelected: (base64Images) {
                            setState(() {
                              selectedImages =
                                  base64Images; // Store the Base64 image strings
                            });
                          },
                        ),
                        SizedBox(height: 20.h),
                        ElevatedButton(
                          onPressed: isLoading ? null : _addingProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.secondaryColor,
                            elevation: 0.2,
                            minimumSize: Size(360.w, 52.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "Add Product",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// For Text Field
class InputTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  const InputTextField(
      {super.key, required this.labelText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText'; // Validation message
        }
        return null; // If the input is valid
      },
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelText: labelText,
      ),
    );
  }
}
