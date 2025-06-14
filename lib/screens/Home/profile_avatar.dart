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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: circle,
        backgroundColor: theme.cardColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(circle),
          child: _buildProfileImage(),
        ),
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
              color: Colors.brown,
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
      errorBuilder: (context, error, stackTrace) {
        // If asset image fails, show a default icon
        return Container(
          width: circle * 2,
          height: circle * 2,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            size: circle * 0.8,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }
}
