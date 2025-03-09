import 'package:capstone/admin/add_product/categoty_admin.dart';
import 'package:capstone/admin/add_product/image_picker.dart';
import 'package:capstone/admin/add_product/select_color.dart';
import 'package:capstone/admin/admin_navbar.dart';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/service/adding_product.dart';
import 'package:capstone/widget/error_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

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
  List<String> selectedSizes = []; // Store selected sizes

  // Adding these maps to store size options per category
  final Map<String, List<String>> categorySizes = {
    'Apparel': ['S', 'M', 'L', 'XL', 'XXL'],
    'Shoes': [
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '36',
      '37',
      '38',
      '39',
      '40',
      '41',
      '42',
      '43',
      '44',
      '45'
    ],
    'Watches': ['Small', 'Medium', 'Large'],
    'Ornaments': ['Small', 'Medium', 'Large'],
    'Sunglasses': ['Small', 'Medium', 'Large']
  };

  // Get current sizes based on selected category
  List<String> get currentSizes {
    if (selectedCategory == null) {
      return []; // No category selected, no sizes
    }
    return categorySizes[selectedCategory] ?? [];
  }

  // Updating onCategorySelected method to clear previously selected sizes when category changes
  void onCategorySelected(String? category) {
    setState(() {
      if (selectedCategory != category) {
        selectedSizes = [];
      }
      selectedCategory = category;
    });
  }

  // Function to add product
  Future<void> _addingProduct() async {
    // Validate if all fields are filled properly
    bool allFieldsValid = titleContorller.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        selectedSizes.isNotEmpty &&
        priceContorller.text.isNotEmpty &&
        selectedColors.isNotEmpty &&
        selectedImages.isNotEmpty;

    if (!allFieldsValid) {
      // Show error message for empty fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All fields are required. Please fill them all."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 3),
        ),
      );
      return; // Stop execution if any field is empty
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      // Show more specific processing message with clear status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  "Processing ${selectedImages.length} ${selectedImages.length == 1 ? 'image' : 'images'} and uploading product. Please wait...",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
          duration: Duration(
              seconds: 40), // Longer duration for processing multiple images
        ),
      );

      try {
        // Convert colors to string format for Firestore
        List<String> colorData =
            selectedColors.map((color) => color.value.toString()).toList();

        // Make sure price is valid
        double? price = double.tryParse(priceContorller.text);
        if (price == null || price <= 0) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please enter a valid price"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(10),
            ),
          );
          return;
        }

        // Call addProduct method with validated data
        // Use a timeout to prevent hanging
        final result = await _addProduct
            .addProduct(
              title: titleContorller.text,
              description: descriptionController.text,
              category: selectedCategory!,
              price: price,
              color: colorData,
              size: selectedSizes, // Pass the sizes as a list directly
              images: selectedImages,
            )
            .timeout(
              Duration(seconds: 30), // 30 second timeout
              onTimeout: () =>
                  "Error: Operation timed out. Try using smaller image files.",
            );

        setState(() {
          isLoading = false;
        });

        // Check if product was added successfully
        if (result.contains("successfully")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Product added successfully!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(10),
              duration: Duration(seconds: 2),
            ),
          );

          // Reset form only on success
          _formKey.currentState?.reset();
          titleContorller.clear();
          descriptionController.clear();
          categoryContorller.clear();
          sizeContorller.clear();
          priceContorller.clear();
          setState(() {
            selectedColors = [];
            selectedImages = [];
            selectedCategory = null;
            selectedSizes = [];
          });
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.replaceAll("Error: ", "")),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(10),
              duration: Duration(seconds: 5), // Show error longer
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "An error occurred. Try with smaller images or check your connection."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Function to toggle size selection
  void _toggleSize(String size) {
    setState(() {
      if (selectedSizes.contains(size)) {
        selectedSizes.remove(size);
      } else {
        selectedSizes.add(size);
      }
    });
  }

  // Add a custom size
  void _addCustomSize() {
    if (sizeContorller.text.isNotEmpty) {
      setState(() {
        selectedSizes.add(sizeContorller.text);
        sizeContorller.clear();
      });
    }
  }

  // Controller for input fields
  TextEditingController titleContorller = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController categoryContorller = TextEditingController();
  TextEditingController sizeContorller = TextEditingController();
  TextEditingController priceContorller = TextEditingController();

  // Helper method to create required field label string
  String _requiredFieldLabel(String labelText) {
    return "$labelText *";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            "Add Product",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AdminNavbar()));
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Form(
              key: _formKey, // Assign the form key here
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Information Section
                          Text(
                            "Product Information",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 15.h),

                          // Title Field
                          InputTextField(
                            controller: titleContorller,
                            labelText:
                                _requiredFieldLabel("Enter Product Title"),
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 15.h),

                          // Description Field with bigger height
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _requiredFieldLabel("Product Description"),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextFormField(
                                controller: descriptionController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      "Enter detailed product description...",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          // Category Selection
                          Text(
                            "Product Details",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 15.h),

                          CategotyAdmin(
                            onCategorySelected: onCategorySelected,
                            initialValue: selectedCategory,
                          ),
                          SizedBox(height: 20.h),

                          // Size Selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Select Sizes",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    " *",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),

                              // Size chips - now using currentSizes from selected category
                              selectedCategory == null
                                  ? Text("Please select a category first",
                                      style: TextStyle(color: Colors.grey))
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: currentSizes.map((size) {
                                        bool isSelected =
                                            selectedSizes.contains(size);
                                        return FilterChip(
                                          label: Text(size),
                                          selected: isSelected,
                                          checkmarkColor: Colors.white,
                                          backgroundColor: Colors.grey[200],
                                          selectedColor:
                                              CustomColors.secondaryColor,
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          onSelected: (bool selected) {
                                            _toggleSize(size);
                                          },
                                        );
                                      }).toList(),
                                    ),

                              // Custom size input
                              SizedBox(height: 10.h),
                              if (selectedCategory !=
                                  null) // Only show if category is selected
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: sizeContorller,
                                        decoration: InputDecoration(
                                          hintText: "Add custom size",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 12),
                                        ),
                                        keyboardType: TextInputType.text,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    ElevatedButton(
                                      onPressed: _addCustomSize,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            CustomColors.secondaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text("Add Size"),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          SizedBox(height: 20.h),

                          // Color Selection
                          SelectAColor(
                            onColorSelected: (colors) {
                              setState(() {
                                selectedColors = colors;
                              });
                            },
                          ),
                          SizedBox(height: 20.h),

                          // Price Field
                          InputTextField(
                            controller: priceContorller,
                            labelText: _requiredFieldLabel("Enter Price"),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 25.h),

                          // Image Selection
                          ImagePickerWidget(
                            imageFiles: selectedImages,
                            onImagesSelected: (images) {
                              setState(() {
                                selectedImages = images;
                              });
                            },
                          ),
                          SizedBox(height: 25.h),

                          // Add Product Button
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _addingProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomColors.secondaryColor,
                                elevation: 2,
                                padding: EdgeInsets.symmetric(vertical: 16),
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
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 30.h),
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
