import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_time.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class PrayerApiService {
  final String baseUrl = 'https://api.aladhan.com/v1';

  // Fetch prayer times for a specific date
  Future<PrayerTime?> fetchDailyPrayerTime(
    double latitude,
    double longitude,
    DateTime date,
    {int? method, int? juristic}
  ) async {
    // Format date as DD-MM-YYYY
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    
    // Build URL with query parameters
    final urlBuilder = StringBuffer(
      '$baseUrl/timings/$formattedDate?latitude=$latitude&longitude=$longitude',
    );
    
    // Add calculation method if specified
    if (method != null) {
      urlBuilder.write('&method=$method');
    }
    
    // Add juristic method if specified
    if (juristic != null) {
      urlBuilder.write('&school=$juristic');
    }
    
    final url = Uri.parse(urlBuilder.toString());
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        try {
          // Parse JSON manually to avoid GSON issues in release mode
          final jsonData = json.decode(response.body);
          
          if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
            try {
              return PrayerTime.fromJson(jsonData['data'], date.millisecondsSinceEpoch);
            } catch (e) {
              debugPrint('Error parsing prayer time: $e');
              return null;
            }
          } else {
            debugPrint('API Error: ${jsonData['data']}');
            return null;
          }
        } catch (e) {
          debugPrint('JSON parsing error: $e');
          return null;
        }
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      return null;
    }
  }

  // Fetch prayer times for an entire year based on coordinates
  Future<List<PrayerTime>> fetchYearlyPrayerTimes(
    double latitude,
    double longitude,
    int year,
    {int? method, int? juristic} // Optional method and juristic parameters
  ) async {
    List<PrayerTime> prayerTimes = [];
    
    try {
      // We'll fetch the data month by month to avoid potential issues with large responses
      for (int month = 1; month <= 12; month++) {
        // Build URL with query parameters
        final urlBuilder = StringBuffer(
          '$baseUrl/calendar/$year/$month?latitude=$latitude&longitude=$longitude',
        );
        
        // Add calculation method if specified
        if (method != null) {
          urlBuilder.write('&method=$method');
        }
        
        // Add juristic method if specified
        if (juristic != null) {
          urlBuilder.write('&school=$juristic');
        }
        
        // Explicitly add annual=true to ensure we get hijri date information
        urlBuilder.write('&annual=true');
        
        final url = Uri.parse(urlBuilder.toString());
        
        try {
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            try {
              final jsonData = json.decode(response.body);
              
              if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
                final data = jsonData['data'];
                
                for (var day in data) {
                  try {
                    PrayerTime prayerTime = PrayerTime.fromJson(day, prayerTimes.length + 1);
                    prayerTimes.add(prayerTime);
                  } catch (e) {
                    debugPrint('Error parsing day data: $e');
                    // Continue with next day
                  }
                }
              } else {
                debugPrint('Failed to load prayer times: ${jsonData['data']}');
              }
            } catch (e) {
              debugPrint('JSON parsing error for month $month: $e');
            }
          } else {
            debugPrint('HTTP error for month $month: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Network error for month $month: $e');
        }
      }
      
      return prayerTimes;
    } catch (e) {
      debugPrint('General error fetching yearly prayer times: $e');
      return [];
    }
  }
} 