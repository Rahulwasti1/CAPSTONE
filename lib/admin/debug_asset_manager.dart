import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capstone/service/asset_organizer_service.dart';
import 'dart:io';

class DebugAssetManager extends StatefulWidget {
  const DebugAssetManager({super.key});

  @override
  State<DebugAssetManager> createState() => _DebugAssetManagerState();
}

class _DebugAssetManagerState extends State<DebugAssetManager> {
  Map<String, int> _imageStats = {};
  List<String> _categories = [
    'Apparel',
    'Shoes',
    'Watches',
    'Ornaments',
    'Sunglasses'
  ];
  String _selectedCategory = 'Apparel';
  List<File> _categoryImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImageStatistics();
    _loadCategoryImages();
  }

  Future<void> _loadImageStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, int> stats = await AssetOrganizerService.getImageStatistics();
      setState(() {
        _imageStats = stats;
      });
    } catch (e) {
      print('Error loading image statistics: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCategoryImages() async {
    try {
      List<File> images =
          await AssetOrganizerService.getImagesInCategory(_selectedCategory);
      setState(() {
        _categoryImages = images;
      });
    } catch (e) {
      print('Error loading category images: $e');
    }
  }

  Future<void> _clearAllImages() async {
    try {
      await AssetOrganizerService.clearAllProductImages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All product images cleared!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadImageStatistics();
      _loadCategoryImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createDirectoryStructure() async {
    try {
      await AssetOrganizerService.createDocumentDirectoryStructure();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Directory structure created!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating directories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Asset Manager'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image Statistics',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          if (_imageStats.isEmpty)
                            Text('No organized images found')
                          else
                            ..._imageStats.entries.map((entry) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text(
                                        '${entry.value} images',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Actions Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                            onPressed: _loadImageStatistics,
                            child: Text('Refresh Statistics'),
                          ),
                          SizedBox(height: 8.h),
                          ElevatedButton(
                            onPressed: _createDirectoryStructure,
                            child: Text('Create Directory Structure'),
                          ),
                          SizedBox(height: 8.h),
                          ElevatedButton(
                            onPressed: _clearAllImages,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Clear All Images'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Category Images Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category Images',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                                _loadCategoryImages();
                              }
                            },
                            items: _categories
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16.h),
                          if (_categoryImages.isEmpty)
                            Text(
                                'No images found in $_selectedCategory category')
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8.w,
                                mainAxisSpacing: 8.h,
                              ),
                              itemCount: _categoryImages.length,
                              itemBuilder: (context, index) {
                                final imageFile = _categoryImages[index];
                                return Card(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image.file(
                                          imageFile,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: Icon(Icons.error),
                                            );
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(4.w),
                                        child: Text(
                                          imageFile.path.split('/').last,
                                          style: TextStyle(fontSize: 10.sp),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
