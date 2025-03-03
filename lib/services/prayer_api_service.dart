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
    debugPrint('Starting to fetch yearly prayer times for year $year at lat: $latitude, long: $longitude');
    List<PrayerTime> prayerTimes = [];
    
    try {
      // REVISED APPROACH: Instead of fetching month by month, fetch the entire year at once
      // Build URL with query parameters for the entire year
      final urlBuilder = StringBuffer(
        '$baseUrl/calendar/$year?latitude=$latitude&longitude=$longitude',
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
      debugPrint('Requesting yearly data with URL: $url');
      
      try {
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          try {
            final jsonData = json.decode(response.body);
            
            if (jsonData['code'] == 200 && jsonData['status'] == 'OK') {
              final data = jsonData['data'];
              
              // Debug output to understand structure
              debugPrint('Data type for year response: ${data.runtimeType}');
              
              // Process data by month
              if (data is Map<String, dynamic>) {
                final sortedMonths = data.keys.toList();
                sortedMonths.sort(); // Sort months
                
                debugPrint('Found ${sortedMonths.length} months in response');
                // Dump direct keys from the data object to see structure
                debugPrint('Direct keys in data: ${data.keys.join(', ')}');
                
                // Print the full structure of month 1 to understand what we're dealing with
                if (data.containsKey('1')) {
                  debugPrint('Examining month 1 structure in detail:');
                  final month1 = data['1'];
                  debugPrint('Month 1 data type: ${month1.runtimeType}');
                  
                  if (month1 is Map<String, dynamic>) {
                    debugPrint('Month 1 is a Map with ${month1.length} entries, keys: ${month1.keys.join(', ')}');
                    
                    // Take a sample of the first entry
                    if (month1.isNotEmpty) {
                      final firstKey = month1.keys.first;
                      final firstEntry = month1[firstKey];
                      debugPrint('First entry key: $firstKey, type: ${firstEntry.runtimeType}');
                      
                      // If it's a list of items, print info about the first item
                      if (firstEntry is List && firstEntry.isNotEmpty) {
                        debugPrint('Entry $firstKey contains a list of ${firstEntry.length} items');
                        if (firstEntry[0] is Map<String, dynamic>) {
                          final item = firstEntry[0];
                          debugPrint('First item keys: ${item.keys.join(', ')}');
                          
                          // Sample out the date and timings
                          if (item.containsKey('date')) {
                            debugPrint('Date structure: ${item['date']}');
                          }
                          if (item.containsKey('timings')) {
                            debugPrint('Timings structure: ${item['timings']}');
                          }
                        }
                      }
                    }
                  } else {
                    // If it's not a Map, print what it is directly
                    debugPrint('Month 1 is NOT a Map but a ${month1.runtimeType}');
                    debugPrint('Month 1 raw data: $month1');
                  }
                } else {
                  debugPrint('No key "1" found in data! Available keys: ${data.keys.join(', ')}');
                }
                
                for (var monthKey in sortedMonths) {
                  final monthData = data[monthKey];
                  int monthNum = int.tryParse(monthKey) ?? 0;
                  
                  debugPrint('Processing month $monthKey data, type: ${monthData.runtimeType}');
                  
                  // NEW HANDLING: Process month data as a List instead of a Map
                  if (monthData is List) {
                    debugPrint('Month $monthKey has ${monthData.length} days');
                    
                    // Debug the first day's data structure if available
                    if (monthData.isNotEmpty) {
                      final firstDayData = monthData[0];
                      debugPrint('First day data type: ${firstDayData.runtimeType}');
                      
                      if (firstDayData is Map<String, dynamic>) {
                        debugPrint('First day keys: ${firstDayData.keys.join(', ')}');
                        
                        // Check if we have the expected structure
                        if (firstDayData.containsKey('date') && firstDayData.containsKey('timings')) {
                          debugPrint('First day has expected structure with date and timings');
                          
                          // Print a sample of the date info
                          if (firstDayData['date'] is Map) {
                            final dateMap = firstDayData['date'] as Map<String, dynamic>;
                            if (dateMap.containsKey('readable')) {
                              debugPrint('Sample date (readable): ${dateMap['readable']}');
                            }
                            if (dateMap.containsKey('gregorian')) {
                              final gregMap = dateMap['gregorian'] as Map<String, dynamic>?;
                              if (gregMap != null && gregMap.containsKey('date')) {
                                debugPrint('Sample gregorian date: ${gregMap['date']}');
                              }
                            }
                          }
                        }
                      }
                    }
                    
                    // Process each day in the list
                    int dayCount = 0;
                    for (var dayData in monthData) {
                      dayCount++;
                      
                      if (dayData is Map<String, dynamic>) {
                        try {
                          // This is a direct prayer time object with timings and date
                          if (dayData.containsKey('timings') && dayData.containsKey('date')) {
                            PrayerTime prayerTime = PrayerTime.fromJson(dayData, prayerTimes.length + 1);
                            prayerTimes.add(prayerTime);
                            
                            // Print first day and last day of each month for verification
                            if (dayCount == 1 || dayCount == monthData.length) {
                              debugPrint('Month $monthKey, Day $dayCount: Date=${prayerTime.date}, Fajr=${prayerTime.fajr}');
                            }
                          } else {
                            debugPrint('Day $dayCount data missing required fields');
                          }
                        } catch (e) {
                          debugPrint('Error parsing day $dayCount data: $e');
                        }
                      } else {
                        debugPrint('Unexpected day data format: ${dayData.runtimeType}');
                      }
                    }
                  } else if (monthData is Map<String, dynamic>) {
                    // Keep the old code for backward compatibility just in case
                    // Get the data for each day in this month
                    final sortedDays = monthData.keys.toList();
                    sortedDays.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                    
                    debugPrint('Month $monthKey has ${sortedDays.length} days, keys: ${sortedDays.take(5).join(', ')}...');
                    
                    // Debug first day's data structure
                    if (sortedDays.isNotEmpty) {
                      final firstDayKey = sortedDays.first;
                      final firstDayData = monthData[firstDayKey];
                      debugPrint('First day data type: ${firstDayData.runtimeType}');
                      
                      if (firstDayData is Map<String, dynamic>) {
                        debugPrint('First day keys: ${firstDayData.keys.join(', ')}');
                        // Check if we have date or timings directly
                        if (firstDayData.containsKey('date') && firstDayData.containsKey('timings')) {
                          debugPrint('Found date and timings keys in day data directly');
                        } else {
                          debugPrint('No date/timings keys found directly');
                        }
                      } else if (firstDayData is List) {
                        debugPrint('First day is a List with ${firstDayData.length} items');
                        if (firstDayData.isNotEmpty) {
                          debugPrint('First item type: ${firstDayData[0].runtimeType}');
                          if (firstDayData[0] is Map<String, dynamic>) {
                            final firstItem = firstDayData[0] as Map<String, dynamic>;
                            debugPrint('First item keys: ${firstItem.keys.join(', ')}');
                            if (firstItem.containsKey('date') && firstItem.containsKey('timings')) {
                              debugPrint('Found date and timings keys in list item');
                            }
                          }
                        }
                      } else {
                        debugPrint('First day data is neither Map nor List but ${firstDayData.runtimeType}');
                        debugPrint('Raw first day data: $firstDayData');
                      }
                    } else {
                      debugPrint('No days found in month $monthKey');
                    }
                    
                    // Also dump the first day directly for inspection
                    if (sortedDays.isNotEmpty) {
                      final firstDayKey = sortedDays.first;
                      debugPrint('First day ($firstDayKey) raw data: ${monthData[firstDayKey]}');
                    }
                    
                    for (var dayKey in sortedDays) {
                      final dayData = monthData[dayKey];
                      
                      // Properly extract data from the API response structure
                      try {
                        Map<String, dynamic>? prayerTimeData;
                        
                        // Check if dayData is a List containing prayer time objects
                        if (dayData is List && dayData.isNotEmpty) {
                          if (dayData[0] is Map<String, dynamic>) {
                            prayerTimeData = dayData[0];
                            debugPrint('Found prayer time data in list format for day $dayKey');
                          }
                        } 
                        // Check if dayData is a Map directly containing prayer time data
                        else if (dayData is Map<String, dynamic>) {
                          // Check if this Map has the expected structure for a prayer time
                          if (dayData.containsKey('timings')) {
                            prayerTimeData = dayData;
                            debugPrint('Found prayer time data in map format for day $dayKey');
                          }
                        }
                        
                        // If we found valid prayer time data, parse it
                        if (prayerTimeData != null) {
                          // Print the actual data we're trying to parse for the first day
                          if (dayKey == sortedDays.first) {
                            debugPrint('Prayer time data structure: $prayerTimeData');
                            if (prayerTimeData.containsKey('date')) {
                              debugPrint('Date format: ${prayerTimeData['date']}');
                            }
                            if (prayerTimeData.containsKey('timings')) {
                              debugPrint('Timings format: ${prayerTimeData['timings']}');
                            }
                          }
                          
                          PrayerTime prayerTime = PrayerTime.fromJson(prayerTimeData, prayerTimes.length + 1);
                          prayerTimes.add(prayerTime);
                          
                          // Print first day and last day of each month for verification
                          if (dayKey == sortedDays.first || dayKey == sortedDays.last) {
                            debugPrint('Month $monthKey, Day $dayKey: Date=${prayerTime.date}, Fajr=${prayerTime.fajr}');
                          }
                        } else {
                          debugPrint('No valid prayer time data found for day $dayKey in month $monthKey');
                        }
                      } catch (e) {
                        debugPrint('Error parsing day $dayKey data: $e');
                      }
                    }
                  } else {
                    debugPrint('Unexpected month data format: ${monthData.runtimeType}');
                  }
                  
                  debugPrint('Finished month $monthKey, total prayer times so far: ${prayerTimes.length}');
                }
              } else {
                debugPrint('Unexpected yearly data format: ${data.runtimeType}');
              }
            } else {
              debugPrint('Failed to load yearly prayer times: ${jsonData['data']}');
            }
          } catch (e) {
            debugPrint('JSON parsing error for yearly data: $e');
          }
        } else {
          debugPrint('HTTP error for yearly request: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Network error for yearly request: $e');
      }
      
      // Summary of results
      final daysInYear = DateTime(year, 1, 0).difference(DateTime(year + 1, 1, 0)).inDays.abs();
      debugPrint('Finished processing all months for year $year. Expected ~$daysInYear days, got ${prayerTimes.length} prayer times.');
      
      return prayerTimes;
    } catch (e) {
      debugPrint('General error fetching yearly prayer times: $e');
      return [];
    }
  }
} 