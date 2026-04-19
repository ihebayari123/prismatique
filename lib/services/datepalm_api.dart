import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;


class DatePalmApi {
  DatePalmApi(this.baseUrl);

  final String baseUrl;

  Future<Map<String, dynamic>> predictDisease(Uint8List imageBytes,
      {String filename = 'image.jpg'}) async {
    try {
      print('🌴 Sending image to disease detection API: $baseUrl/predict-disease');
      final uri = Uri.parse('$baseUrl/predict-disease');
      final req = http.MultipartRequest('POST', uri);
      
      // Add the image file with proper content type
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: _getContentType(filename),
        ),
      );

      print('🌴 Sending multipart request with file: $filename (${imageBytes.length} bytes)');
      final streamed = await req.send().timeout(const Duration(seconds: 180));
      final body = await streamed.stream.bytesToString();

      print('🌴 Disease detection response: ${streamed.statusCode}');
      print('🌴 Response body: $body');
      
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        print('❌ API error ${streamed.statusCode}: $body');
        throw Exception('API error ${streamed.statusCode}: $body');
      }
      print('✅ Disease detection successful');
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error predicting disease: $e');
      rethrow;
    }
  }

  Future<Uint8List> segment(Uint8List imageBytes,
      {double threshold = 0.5, String filename = 'image.jpg'}) async {
    try {
      print(
          '🌴 Segmenting image with threshold $threshold: $baseUrl/segment');
      final uri = Uri.parse('$baseUrl/segment?threshold=$threshold');
      final req = http.MultipartRequest('POST', uri);
      
      // Add the image file with proper content type
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: _getContentType(filename),
        ),
      );

      print('🌴 Sending segmentation request with file: $filename (${imageBytes.length} bytes)');
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();

      print('🌴 Segmentation response: ${streamed.statusCode}');
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        print('❌ API error ${streamed.statusCode}: $body');
        throw Exception('API error ${streamed.statusCode}: $body');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final b64 = json['mask_png_base64'] as String;
      print('✅ Segmentation successful');
      return base64Decode(b64);
    } catch (e) {
      print('❌ Error segmenting image: $e');
      rethrow;
    }
  }

  // Helper to get proper MIME type based on filename
  static dynamic _getContentType(String filename) {
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) {
      return _parseMediaType('image/jpeg');
    } else if (filename.endsWith('.png')) {
      return _parseMediaType('image/png');
    } else if (filename.endsWith('.gif')) {
      return _parseMediaType('image/gif');
    }
    return _parseMediaType('image/jpeg'); // default
  }

  static dynamic _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    return http.MediaType(parts[0], parts[1]);
  }
}
