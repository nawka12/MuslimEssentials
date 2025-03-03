import 'dart:convert';
import 'package:http/http.dart' as http;

class QiblaApiService {
  final String baseUrl = 'https://api.aladhan.com/v1';

  // Fetch Qibla direction based on latitude and longitude
  Future<double?> getQiblaDirection(double latitude, double longitude) async {
    final url = Uri.parse('$baseUrl/qibla/$latitude/$longitude');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
          // Extract the direction in degrees
          return double.parse(jsonData['data']['direction'].toString());
        } else {
          print('API Error: ${jsonData['data']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during API call: $e');
      return null;
    }
  }
} 