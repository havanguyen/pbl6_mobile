import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class UtilitiesService {
  const UtilitiesService._();

  static final Dio _secureDio = AuthService.getSecureDioInstance();

  static Future<Map<String, dynamic>?> getUploadSignature() async {
    try {
      print("🚀 [UtilitiesService] Requesting upload signature...");
      final response = await _secureDio.post('/utilities/upload-signature');
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ [UtilitiesService] Got upload signature successfully.");
        return response.data['data'];
      }
      print("⚠️ [UtilitiesService] Failed to get signature. Status: ${response.statusCode}, Body: ${response.data}");
      return null;
    } catch (e) {
      print("🔥 [UtilitiesService] Error getting upload signature: $e");
      if (e is DioException) {
        print("   - DioException Response: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<String?> uploadImageToCloudinary(
      String filePath, Map<String, dynamic> signatureData) async {
    try {
      final dio = Dio();
      String fileName = filePath.split(Platform.pathSeparator).last;
      print("🚀 [UtilitiesService] Uploading '$fileName' to Cloudinary...");

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'api_key': signatureData['apiKey'],
        'timestamp': signatureData['timestamp'],
        'signature': signatureData['signature'],
        if (signatureData.containsKey('folder') && signatureData['folder'] != null)
          'folder': signatureData['folder'],
      });

      final cloudName = signatureData['cloudName'];
      if (cloudName == null) {
        print("🔥 [UtilitiesService] Error: Cloud name is missing in signature data.");
        return null;
      }

      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
        onSendProgress: (int sent, int total) {

        },
      );

      if (response.statusCode == 200 && response.data != null && response.data['secure_url'] != null) {
        final secureUrl = response.data['secure_url'];
        print("✅ [UtilitiesService] Upload successful. Secure URL: $secureUrl");
        return secureUrl;
      } else {
        print("⚠️ [UtilitiesService] Cloudinary upload failed. Status: ${response.statusCode}, Body: ${response.data}");
        return null;
      }
    } catch (e) {
      print("🔥 [UtilitiesService] Error uploading to Cloudinary: $e");
      if (e is DioException) {
        print("   - DioException Response: ${e.response?.data}");
      }
      return null;
    }
  }
}