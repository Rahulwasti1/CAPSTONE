import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

// NOTE FOR FLASK SERVER:
// To make your Flask app accessible from mobile devices on your network,
// you need to modify how you run the Flask app.
// Instead of: python app.py
// Use: python app.py --host=0.0.0.0
// Or add this to your app.py file at the bottom:
// if __name__ == '__main__':
//     app.run(debug=True, host='0.0.0.0')
//
// This will make your Flask server listen on all network interfaces
// instead of just localhost (127.0.0.1)

class VirtualTryOnService {
  // Base URL for the API server
  // The Flask server is running on http://127.0.0.1:5000
  // BUT we need to use different URLs depending on the platform:
  // - For iOS simulator: http://localhost:5000 or http://127.0.0.1:5000
  // - For Android emulator: http://10.0.2.2:5000 (special Android IP that routes to host's localhost)
  // - For physical devices: Use the computer's actual IP address on your network (e.g., 192.168.1.x)

  // Get the appropriate base URL based on platform
  static String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator special case
      return 'http://10.0.2.2:5000';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS simulator can use localhost
      return 'http://localhost:5000';
    } else {
      // For physical devices, you need the actual IP address
      // IMPORTANT: Change this to your computer's IP address when testing on physical devices
      return 'http://192.168.1.66:5000'; // Your actual IP address
    }
  }

  // First send the glasses image to the server
  Future<bool> setSunglasses(String glassesImageBase64) async {
    try {
      final apiUrl = '${getBaseUrl()}/set_sunglass';

      // Log API call info
      developer.log('Sending sunglasses to $apiUrl');

      // Create the request payload - ensure proper base64 format with data URI
      final String formattedBase64 = _formatBase64ForAPI(glassesImageBase64);
      final Map<String, dynamic> requestBody = {
        'sunglasses': formattedBase64,
      };

      // Make the POST request
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      // Check if the request was successful
      if (response.statusCode == 200) {
        developer.log('Successfully set sunglasses');
        return true;
      } else {
        developer
            .log('API request failed with status code: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      developer.log('Error setting sunglasses: $e');
      return false;
    }
  }

  // Then apply the sunglasses to the face image
  Future<String?> applySunglasses(String faceImageBase64) async {
    try {
      final apiUrl = '${getBaseUrl()}/apply';

      // Log API call info
      developer.log('Sending face image to $apiUrl');

      // Create the request payload - ensure proper base64 format with data URI
      final String formattedBase64 = _formatBase64ForAPI(faceImageBase64);
      final Map<String, dynamic> requestBody = {
        'frame': formattedBase64,
      };

      // Make the POST request
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Get the result image as base64
        final String? resultImage = responseData['output_frame'];

        if (resultImage != null && resultImage.isNotEmpty) {
          developer.log('Successfully received processed image');
          return resultImage;
        } else {
          developer.log('No result image in response');
          return null;
        }
      } else {
        developer
            .log('API request failed with status code: ${response.statusCode}');
        developer.log('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('Error applying sunglasses: $e');
      return null;
    }
  }

  // Helper function to format base64 strings for the API
  String _formatBase64ForAPI(String base64String) {
    // Check if the string already has a data URI prefix
    if (base64String.startsWith('data:image')) {
      return base64String;
    }

    // Add the data URI prefix if it doesn't have one
    return 'data:image/jpeg;base64,$base64String';
  }

  // Test connection to the server
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(getBaseUrl()))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error testing connection: $e');
      return false;
    }
  }
}
