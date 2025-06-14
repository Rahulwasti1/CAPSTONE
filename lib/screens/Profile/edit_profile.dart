import 'dart:io';
import 'dart:convert';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as developer;

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String? currentPhotoUrl;
  final String? currentPhotoBase64;

  const EditProfileScreen({
    Key? key,
    required this.currentName,
    this.currentPhotoUrl,
    this.currentPhotoBase64,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  File? _selectedImage;
  bool _isLoading = false;
  String? _photoUrl;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _photoUrl = widget.currentPhotoUrl;
    _photoBase64 = widget.currentPhotoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      // Process the image to get URL and base64
      await _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert to base64
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Upload to Firebase Storage for URL
      String? imageUrl = await _uploadImage();

      setState(() {
        _photoUrl = imageUrl;
        _photoBase64 = base64Image;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final String fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      developer.log('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Firestore with new profile data
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _nameController.text.trim(),
        'photoUrl': _photoUrl,
        'photoBase64': _photoBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Return the updated profile info to the previous screen
      Navigator.pop(context, {
        'username': _nameController.text.trim(),
        'photoUrl': _photoUrl,
        'photoBase64': _photoBase64,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      // Use the selected local image if available
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_selectedImage!),
      );
    } else if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      // Use base64 image if available
      try {
        return CircleAvatar(
          radius: 60,
          backgroundImage: MemoryImage(base64Decode(_photoBase64!)),
        );
      } catch (e) {
        developer.log('Error decoding base64 image: $e');
      }
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      // Use URL image if available
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_photoUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          developer.log('Error loading network image: $exception');
        },
      );
    }

    // Default image
    return CircleAvatar(
      radius: 60,
      backgroundImage: AssetImage('assets/images/userr.png'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAppbar(text: "Edit Profile"),
              SizedBox(height: 24.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      // Profile image
                      Stack(
                        children: [
                          _buildProfileImage(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: CustomColors.secondaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      // Name field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4.w),
                            child: Text(
                              "Full Name",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: "Enter your name",
                              filled: true,
                              fillColor:
                                  const Color.fromARGB(255, 240, 238, 238),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: BorderSide(
                                  color:
                                      const Color.fromARGB(255, 240, 238, 238),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: BorderSide(
                                  color: CustomColors.secondaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40.h),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfileChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
