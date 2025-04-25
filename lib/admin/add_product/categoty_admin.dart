import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategotyAdmin extends StatefulWidget {
  final Function(String?) onCategorySelected;
  final Function(String?) onGenderCategorySelected;
  final String? initialValue;
  final String? initialGenderValue;

  const CategotyAdmin({
    super.key,
    required this.onCategorySelected,
    required this.onGenderCategorySelected,
    this.initialValue,
    this.initialGenderValue,
  });

  @override
  State<CategotyAdmin> createState() => _CategotyAdminState();
}

class _CategotyAdminState extends State<CategotyAdmin> {
  // Product Category Dropdown
  String? selectedValue;
  // Gender Category Dropdown
  String? selectedGenderValue;

  // Product type categories
  List<String> productOptions = [
    'Apparel',
    'Shoes',
    'Watches',
    'Ornaments',
    'Sunglasses',
  ];

  // Gender categories
  List<String> genderOptions = [
    'Men',
    'Women',
    'Kids',
    'Unisex',
  ];

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    selectedGenderValue = widget.initialGenderValue;
  }

  @override
  void didUpdateWidget(CategotyAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the selected values if the initialValues change
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        selectedValue = widget.initialValue;
      });
    }

    if (widget.initialGenderValue != oldWidget.initialGenderValue) {
      setState(() {
        selectedGenderValue = widget.initialGenderValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gender Category Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Select Gender Category",
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
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: DropdownButton<String>(
                      value: selectedGenderValue,
                      hint: Text("Select Gender Category"),
                      isExpanded: true,
                      items: genderOptions.map((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedGenderValue = newValue;
                        });
                        widget.onGenderCategorySelected(newValue);
                      }),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Product Category Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Select Product Category",
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
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: DropdownButton<String>(
                      value: selectedValue,
                      hint: Text("Select Product Category"),
                      isExpanded: true,
                      items: productOptions.map((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedValue = newValue;
                        });
                        widget.onCategorySelected(newValue);
                      }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
