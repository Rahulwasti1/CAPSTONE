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
  String? selectedCategory;

// Function to add product
  Future<void> _addingProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      // Converting selected colors to a list of strings
      List<String> colorData =
          selectedColors.map((color) => color.value.toString()).toList();

      // Converting price to double
      double price = double.tryParse(priceContorller.text) ?? 0.0;

      // Call addProduct method and pass the data as parameters
      final result = await _addProduct.addProduct(
        title: titleContorller.text,
        description: descriptionController.text,
        category: selectedCategory ?? '',
        price: price,
        color: colorData,
        size: sizeContorller.text,
        images: selectedImages, // Passing the selected images
      );

      setState(() {
        isLoading = false;
      });

      // Showing success or error message using a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );

      // Reseting the form and clear all input fields if the product is added successfully
      if (result == "Product added successfully!") {
        _formKey.currentState?.reset();
        titleContorller.clear();
        descriptionController.clear();
        categoryContorller.clear();
        sizeContorller.clear();
        priceContorller.clear();
        setState(() {
          selectedColors = [];
          selectedImages = [];
        });
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
        appBar: AppBar(backgroundColor: Colors.white, actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: IconButton.styleFrom(
                    side: BorderSide(
                      width: 2.w,
                      color: Color.fromARGB(255, 241, 239, 239),
                    ),
                  ),
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
            ],
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 140),
            child: Text(
              "Add Product",
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
            ),
          )
        ]),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Form(
              key: _formKey, // Assign the form key here
              child: SafeArea(
                child: Column(
                  children: [
                    // AdminAppbar(name: 'Add Product'),

                    // child: Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 10),
                    //   child: Column(
                    //     children: [

                    SizedBox(height: 15.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          InputTextField(
                            controller: titleContorller,
                            labelText: "Enter Product Title",
                            keyboardType: TextInputType.none,
                          ),
                          SizedBox(height: 15.h),
                          InputTextField(
                            controller: descriptionController,
                            labelText: "Enter Product Description",
                            keyboardType: TextInputType.none,
                          ),
                          SizedBox(height: 15.h),
                          CategotyAdmin(
                            onCategorySelected: (category) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
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
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 15.h),
                          InputTextField(
                              controller: priceContorller,
                              labelText: "Enter Price",
                              keyboardType: TextInputType.number),
                          SizedBox(height: 20.h),
                          // ImagePickerWidget(
                          //   imageFiles: [],
                          //   onImagesSelected: (base64Images) {
                          //     setState(() {
                          //       selectedImages =
                          //           base64Images; // Store the Base64 image strings
                          //     });
                          //   },
                          // ),
                          ImagePickerWidget(
                            imageFiles: selectedImages,
                            onImagesSelected: (images) {
                              setState(() {
                                selectedImages =
                                    images; // Update the selected images list
                              });
                            },
                          ),
                          SizedBox(height: 15.h),
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
            )));
  }
}

// For Text Field
class InputTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const InputTextField(
      {super.key,
      required this.labelText,
      required this.controller,
      required this.keyboardType});

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
      keyboardType: keyboardType,
    );
  }
}
