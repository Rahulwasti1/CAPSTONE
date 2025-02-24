import 'package:capstone/admin/addProduct/imagePicker.dart';
import 'package:capstone/admin/addProduct/selectColor.dart';
import 'package:capstone/admin/addProduct/selectSize.dart';
import 'package:capstone/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminAddProduct extends StatefulWidget {
  const AdminAddProduct({
    super.key,
  });

  @override
  State<AdminAddProduct> createState() => _AdminAddProductState();
}

class _AdminAddProductState extends State<AdminAddProduct> {
  // Category Dropdown
  String? selectedValue;
  List<String> options = [
    'Apparel',
    'Shoes',
    'Watches',
    'Ornaments',
    'Sunglasses'
  ];

  List<String> multipleProduct = [''];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      style: IconButton.styleFrom(
                          side: BorderSide(
                              width: 2.w,
                              color: Color.fromARGB(255, 241, 239, 239))),
                      icon: Icon(Icons.arrow_back)),
                  SizedBox(width: 90.w),
                  Text(
                    "Add Product",
                    style:
                        TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
                  )
                ],
              ),
              SizedBox(height: 15.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    InputTextField(
                      labelText: "Enter Product Title",
                    ),
                    SizedBox(height: 15.h),
                    InputTextField(
                      labelText: "Enter Product Description",
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: 360,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: DropdownButton<String>(
                              value: selectedValue,
                              hint: Text("Select a Category"),
                              isExpanded: true,
                              items: options.map((String value) {
                                return DropdownMenuItem<String>(
                                    value: value, child: Text(value));
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedValue = newValue;
                                });
                              }),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    SelectAColor(),
                    SizedBox(height: 15.h),
                    // SizedBox(height: 59.h, child: Addsize()),
                    InputTextField(
                      labelText: "Enter Size",
                    ),
                    SizedBox(height: 15.h),
                    Imagepicker(),

                    SizedBox(height: 30.h),
                    ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.secondaryColor,
                            elevation: 0.2,
                            minimumSize: Size(360.w, 52.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text(
                          "Add Product",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ))
                  ],
                ),
              )
            ],
          ),
        )),
      ),
    );
  }
}

//  For Text Field

class InputTextField extends StatelessWidget {
  final String labelText;
  const InputTextField({super.key, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelText: labelText),
    );
  }
}
