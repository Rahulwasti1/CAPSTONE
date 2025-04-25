import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ProfileAvatar extends StatelessWidget {
  final double circle;
  final String? imageUrl;
  final String? imageBase64;

  const ProfileAvatar({
    super.key,
    required this.circle,
    this.imageUrl,
    this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: circle,
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(circle),
        child: _buildProfileImage(),
      ),
    );
  }

  Widget _buildProfileImage() {
    // Try to use base64 image first if available
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(imageBase64!);
        return Image.memory(
          imageBytes,
          width: circle * 2,
          height: circle * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            developer.log('Error displaying base64 image: $error');
            return _buildNetworkOrFallbackImage();
          },
        );
      } catch (e) {
        developer.log('Error decoding base64 image: $e');
        // If base64 decoding fails, fall back to URL or default image
        return _buildNetworkOrFallbackImage();
      }
    } else {
      // If no base64, try URL or default
      return _buildNetworkOrFallbackImage();
    }
  }

  Widget _buildNetworkOrFallbackImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: circle * 2,
        height: circle * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading network image: $error');
          return _buildFallbackImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2.0,
            ),
          );
        },
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      "assets/images/userr.png",
      width: circle * 2,
      height: circle * 2,
      fit: BoxFit.cover,
    );
  }
}
