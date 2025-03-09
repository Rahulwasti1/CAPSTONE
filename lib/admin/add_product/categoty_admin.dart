import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategotyAdmin extends StatefulWidget {
  final Function(String?) onCategorySelected;
  final String? initialValue;

  const CategotyAdmin({
    super.key,
    required this.onCategorySelected,
    this.initialValue,
  });

  @override
  State<CategotyAdmin> createState() => _CategotyAdminState();
}

class _CategotyAdminState extends State<CategotyAdmin> {
  // Category Dropdown
  String? selectedValue;
  List<String> options = [
    'Apparel',
    'Shoes',
    'Watches',
    'Ornaments',
    'Sunglasses'
  ];

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(CategotyAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the selected value if the initialValue changes
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        selectedValue = widget.initialValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              hint: Row(
                children: [
                  Text("Select a Category"),
                  Text(
                    " *",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              isExpanded: true,
              items: options.map((String value) {
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
    );
  }
}
