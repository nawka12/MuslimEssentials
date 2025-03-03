import 'package:flutter/foundation.dart';

class PrayerTime {
  final int id;
  final String date; // Format: yyyy-MM-dd
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  
  // Hijri date information
  final String hijriDate;      // DD-MM-YYYY format
  final String hijriDay;       // Day number
  final String hijriWeekday;   // Weekday name in English
  final String hijriMonth;     // Month name in English
  final String hijriYear;      // Hijri year

  PrayerTime({
    required this.id,
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.hijriDate = '',
    this.hijriDay = '',
    this.hijriWeekday = '',
    this.hijriMonth = '',
    this.hijriYear = '',
  });

  // Create a PrayerTime from a JSON map
  factory PrayerTime.fromJson(Map<String, dynamic> json, int id) {
    try {
      final Map<String, dynamic> timings = json['timings'] as Map<String, dynamic>;
      
      // Initialize Hijri date fields with defaults
      String hijriDate = '';
      String hijriDay = '';
      String hijriWeekday = '';
      String hijriMonth = '';
      String hijriYear = '';
      
      // Extract date information safely
      String gregorianDate = '';
      if (json.containsKey('date') && json['date'] is Map) {
        final dateData = json['date'] as Map<String, dynamic>;
        
        // Extract Hijri date information if available
        if (dateData.containsKey('hijri') && dateData['hijri'] is Map) {
          final hijriData = dateData['hijri'] as Map<String, dynamic>;
          
          hijriDate = hijriData['date']?.toString() ?? '';
          hijriDay = hijriData['day']?.toString() ?? '';
          
          if (hijriData.containsKey('weekday') && hijriData['weekday'] is Map) {
            hijriWeekday = hijriData['weekday']['en']?.toString() ?? '';
          }
          
          if (hijriData.containsKey('month') && hijriData['month'] is Map) {
            hijriMonth = hijriData['month']['en']?.toString() ?? '';
          }
          
          hijriYear = hijriData['year']?.toString() ?? '';
        }
        
        // Extract Gregorian date
        if (dateData.containsKey('gregorian') && dateData['gregorian'] is Map) {
          final gregorianData = dateData['gregorian'] as Map<String, dynamic>;
          gregorianDate = gregorianData['date']?.toString() ?? '';
        }
      }
      
      return PrayerTime(
        id: id,
        date: gregorianDate,
        fajr: timings['Fajr']?.toString() ?? '00:00',
        sunrise: timings['Sunrise']?.toString() ?? '00:00',
        dhuhr: timings['Dhuhr']?.toString() ?? '00:00',
        asr: timings['Asr']?.toString() ?? '00:00',
        maghrib: timings['Maghrib']?.toString() ?? '00:00',
        isha: timings['Isha']?.toString() ?? '00:00',
        hijriDate: hijriDate,
        hijriDay: hijriDay,
        hijriWeekday: hijriWeekday,
        hijriMonth: hijriMonth,
        hijriYear: hijriYear,
      );
    } catch (e, stackTrace) {
      debugPrint('Error creating PrayerTime from JSON: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return a default prayer time object
      return PrayerTime(
        id: id,
        date: '',
        fajr: '00:00',
        sunrise: '00:00',
        dhuhr: '00:00',
        asr: '00:00',
        maghrib: '00:00',
        isha: '00:00',
      );
    }
  }

  // Convert a PrayerTime to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'hijri_date': hijriDate,
      'hijri_day': hijriDay,
      'hijri_weekday': hijriWeekday,
      'hijri_month': hijriMonth,
      'hijri_year': hijriYear,
    };
  }

  // Create a PrayerTime from a database map
  factory PrayerTime.fromMap(Map<String, dynamic> map) {
    try {
      return PrayerTime(
        id: map['id'] as int,
        date: map['date']?.toString() ?? '',
        fajr: map['fajr']?.toString() ?? '00:00',
        sunrise: map['sunrise']?.toString() ?? '00:00',
        dhuhr: map['dhuhr']?.toString() ?? '00:00',
        asr: map['asr']?.toString() ?? '00:00',
        maghrib: map['maghrib']?.toString() ?? '00:00',
        isha: map['isha']?.toString() ?? '00:00',
        hijriDate: map['hijri_date']?.toString() ?? '',
        hijriDay: map['hijri_day']?.toString() ?? '',
        hijriWeekday: map['hijri_weekday']?.toString() ?? '',
        hijriMonth: map['hijri_month']?.toString() ?? '',
        hijriYear: map['hijri_year']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Error creating PrayerTime from Map: $e');
      // Return a default prayer time object
      return PrayerTime(
        id: map['id'] as int? ?? -1,
        date: '',
        fajr: '00:00',
        sunrise: '00:00',
        dhuhr: '00:00',
        asr: '00:00',
        maghrib: '00:00',
        isha: '00:00',
      );
    }
  }
  
  // Format Hijri date in a readable format
  String getFormattedHijriDate() {
    if (hijriDate.isEmpty) return '';
    return '$hijriDay $hijriMonth $hijriYear AH';
  }
} 