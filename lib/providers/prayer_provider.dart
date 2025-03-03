import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_time.dart';
import '../services/database_helper.dart';
import '../services/prayer_api_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'prayer_settings_provider.dart';
import '../localizations/app_localizations.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final PrayerApiService _apiService = PrayerApiService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final PrayerSettingsProvider _settingsProvider;
  
  bool _isLoading = false;
  bool _isBackgroundLoading = false;
  String _errorMessage = '';
  PrayerTime? _currentPrayerTime;
  List<PrayerTime> _allPrayerTimes = [];
  String _locationName = '';
  
  // Constructor with required settings provider
  PrayerTimesProvider(this._settingsProvider);
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isBackgroundLoading => _isBackgroundLoading;
  String get errorMessage => _errorMessage;
  PrayerTime? get currentPrayerTime => _currentPrayerTime;
  List<PrayerTime> get allPrayerTimes => _allPrayerTimes;
  String get locationName => _locationName;
  
  // Initialize the provider and load today's prayer times
  Future<void> initialize([BuildContext? context]) async {
    // Make sure settings are initialized first
    if (!_settingsProvider.isInitialized) {
      await _settingsProvider.initialize();
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load today's prayer times from database
      await loadTodayPrayerTimes();
      
      // Load all saved prayer times
      _allPrayerTimes = await _databaseHelper.getAllPrayerTimes();
      
      // Load saved location name
      try {
        String savedLocationName = await _databaseHelper.getLocationName();
        if (savedLocationName.isNotEmpty) {
          _locationName = savedLocationName;
          notifyListeners();
        }
      } catch (e) {
        print('Error loading location name: $e');
      }
      
      // Schedule notifications for today if enabled and context is available
      // Only schedule notifications immediately if we have a valid context
      if (_settingsProvider.notificationsEnabled && _currentPrayerTime != null && context != null) {
        await scheduleNotificationsForToday(context);
      }
    } catch (e) {
      _errorMessage = 'Error initializing: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load today's prayer times from local database
  Future<void> loadTodayPrayerTimes() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Get today's date in the format 'dd-MM-yyyy' to match how it's stored in the database
      String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _currentPrayerTime = await _databaseHelper.getPrayerTimeByDate(today);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading prayer times: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load all prayer times from local database
  Future<void> loadAllPrayerTimes() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _allPrayerTimes = await _databaseHelper.getAllPrayerTimes();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading all prayer times: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch and save today's prayer time quickly
  Future<void> fetchDailyPrayerTimes([BuildContext? context]) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Get current position
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _errorMessage = 'Failed to get current location';
        notifyListeners();
        return;
      }
      
      // Try to get the location name
      try {
        final placemark = await _locationService.getPlacemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        if (placemark != null) {
          // Format the location name based on available information
          List<String> locationParts = [];
          
          if (placemark.locality?.isNotEmpty ?? false) {
            locationParts.add(placemark.locality!);
          }
          
          if (placemark.administrativeArea?.isNotEmpty ?? false) {
            locationParts.add(placemark.administrativeArea!);
          }
          
          if (placemark.country?.isNotEmpty ?? false) {
            locationParts.add(placemark.country!);
          }
          
          _locationName = locationParts.join(', ');
          
          // Save the location name to the database
          await _databaseHelper.saveLocationName(_locationName);
        }
      } catch (e) {
        print('Error getting location name: $e');
        _locationName = 'Unknown Location';
        await _databaseHelper.saveLocationName(_locationName);
      }
      
      // Get settings - always use defaults now
      final calculationMethod = -1; // defaultCalculationMethod (closest authority)
      final juristicMethod = 0; // defaultJuristicMethod (Standard Shafi, Hanbali, Maliki)
      
      // Fetch today's prayer times
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      
      final todayPrayerTime = await _apiService.fetchDailyPrayerTime(
        position?.latitude ?? 0.0,
        position?.longitude ?? 0.0,
        today,
        method: null, // Always use null for method to use closest authority
        juristic: juristicMethod,
      );
      
      final tomorrowPrayerTime = await _apiService.fetchDailyPrayerTime(
        position?.latitude ?? 0.0,
        position?.longitude ?? 0.0,
        tomorrow,
        method: null, // Always use null for method to use closest authority
        juristic: juristicMethod,
      );
      
      // Save to database
      if (todayPrayerTime != null) {
        await _databaseHelper.insertPrayerTime(todayPrayerTime);
        _currentPrayerTime = todayPrayerTime;
      }
      
      if (tomorrowPrayerTime != null) {
        await _databaseHelper.insertPrayerTime(tomorrowPrayerTime);
      }
      
      // Fetch yearly prayer times in background
      _fetchYearlyPrayerTimesInBackground(position?.latitude ?? 0.0, position?.longitude ?? 0.0);
      
      // Schedule notifications if enabled
      if (_settingsProvider.notificationsEnabled) {
        await scheduleNotificationsForToday(context);
      }
      
    } catch (e) {
      _errorMessage = 'Error fetching prayer times: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch and save prayer times for a year from the API in the background
  Future<void> _fetchYearlyPrayerTimesInBackground(double latitude, double longitude) async {
    _isBackgroundLoading = true;
    notifyListeners();
    
    try {
      // Get current year
      final int currentYear = DateTime.now().year;
      
      // Get settings - always use defaults now
      final calculationMethod = -1; // defaultCalculationMethod (closest authority)
      final juristicMethod = 0; // defaultJuristicMethod (Standard Shafi, Hanbali, Maliki)
      
      // Fetch prayer times for the year with the default methods
      final prayerTimes = await _apiService.fetchYearlyPrayerTimes(
        latitude,
        longitude,
        currentYear,
        method: null, // Always use null for method to use closest authority
        juristic: juristicMethod,
      );
      
      // Use insertOrReplacePrayerTimes instead of insertPrayerTimes
      await _databaseHelper.insertOrReplacePrayerTimes(prayerTimes);
      
    } catch (e) {
      print('Background loading error: $e');
    } finally {
      _isBackgroundLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch and save prayer times for a year from the API (deprecated but kept for direct full-year loading)
  Future<void> fetchAndSavePrayerTimes([BuildContext? context]) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Get current position
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _errorMessage = 'Failed to get current location';
        notifyListeners();
        return;
      }
      
      // Try to get and save the location name
      try {
        final placemark = await _locationService.getPlacemarkFromCoordinates(
          position?.latitude ?? 0.0, 
          position?.longitude ?? 0.0
        );
        if (placemark != null) {
          // Format the location name based on available information
          List<String> locationParts = [];
          
          if (placemark.locality?.isNotEmpty ?? false) {
            locationParts.add(placemark.locality!);
          }
          
          if (placemark.administrativeArea?.isNotEmpty ?? false) {
            locationParts.add(placemark.administrativeArea!);
          }
          
          if (placemark.country?.isNotEmpty ?? false) {
            locationParts.add(placemark.country!);
          }
          
          _locationName = locationParts.join(', ');
          
          // Save the location name to the database
          await _databaseHelper.saveLocationName(_locationName);
        }
      } catch (e) {
        print('Error getting location name: $e');
      }
      
      // Get settings - always use defaults now
      final calculationMethod = -1; // defaultCalculationMethod (closest authority)
      final juristicMethod = 0; // defaultJuristicMethod (Standard Shafi, Hanbali, Maliki)
      
      // Get current year
      final int currentYear = DateTime.now().year;
      
      // Fetch prayer times for the year with the default methods
      final prayerTimes = await _apiService.fetchYearlyPrayerTimes(
        position?.latitude ?? 0.0,
        position?.longitude ?? 0.0,
        currentYear,
        method: null, // Always use null for method to use closest authority
        juristic: juristicMethod,
      );
      
      // Clear existing data
      await _databaseHelper.deleteAllPrayerTimes();
      
      // Insert new data
      await _databaseHelper.insertPrayerTimes(prayerTimes);
      
      // Load today's prayer time
      await loadTodayPrayerTimes();
      
      // Schedule notifications if enabled
      if (_settingsProvider.notificationsEnabled) {
        await scheduleNotificationsForToday(context);
      }
      
    } catch (e) {
      _errorMessage = 'Error fetching prayer times: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Schedule notifications for today's prayer times
  Future<void> scheduleNotificationsForToday([BuildContext? context]) async {
    if (_currentPrayerTime == null) {
      print('Cannot schedule notifications: No prayer times available');
      return;
    }
    
    // If context is not available, we can't localize properly, so don't schedule
    if (context == null) {
      print('Cannot schedule notifications: Context is not available for localization');
      return;
    }
    
    // Cancel existing notifications first
    await _notificationService.cancelAllNotifications();
    
    // Only proceed if notifications are enabled
    if (!_settingsProvider.notificationsEnabled) {
      return;
    }
    
    // Prepare localized prayer names
    final localizedPrayerNames = {
      'fajr': t(context, 'fajr'),
      'dhuhr': t(context, 'dhuhr'),
      'asr': t(context, 'asr'),
      'maghrib': t(context, 'maghrib'),
      'isha': t(context, 'isha'),
      'prayer': t(context, 'nav_prayer_times'),
    };
    
    // Schedule with localized strings
    await _notificationService.schedulePrayerTimeNotifications(
      prayerTime: _currentPrayerTime!,
      enabledPrayers: _settingsProvider.enabledPrayerNotifications,
      minutesBefore: _settingsProvider.notificationMinutesBefore,
      localizedPrayerNames: localizedPrayerNames,
      bodyTextFormatter: (prayerName, minutes) => 
        t(context, 'get_notified_minutes_before_prayer_time', args: [minutes.toString()]),
    );
    
    print('Notifications scheduled successfully with localization');
  }
  
  // Get the next prayer time
  Map<String, dynamic>? getNextPrayer() {
    if (_currentPrayerTime == null) {
      return null;
    }
    
    Map<String, String> prayerTimes = {
      'Fajr': _currentPrayerTime!.fajr,
      'Sunrise': _currentPrayerTime!.sunrise,
      'Dhuhr': _currentPrayerTime!.dhuhr,
      'Asr': _currentPrayerTime!.asr,
      'Maghrib': _currentPrayerTime!.maghrib,
      'Isha': _currentPrayerTime!.isha,
    };
    
    return _getNextPrayer(prayerTimes);
  }
  
  // Helper method to determine next prayer
  Map<String, dynamic> _getNextPrayer(Map<String, String> prayerTimes) {
    List<String> prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    DateTime now = DateTime.now();
    String nextPrayer = '';
    DateTime? nextPrayerTime;
    
    // Find the next prayer
    for (String prayer in prayerNames) {
      try {
        String timeString = prayerTimes[prayer]!;
        
        // Extract only the time part before timezone if present
        String timeOnly = timeString;
        if (timeString.contains('(')) {
          timeOnly = timeString.substring(0, timeString.indexOf('(')).trim();
        }
        
        List<String> parts = timeOnly.split(':');
        if (parts.length < 2) {
          continue; // Skip if format is unexpected
        }
        
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        DateTime prayerDateTime = DateTime(
          now.year, now.month, now.day, hour, minute);
        
        if (prayerDateTime.isAfter(now)) {
          nextPrayer = prayer;
          nextPrayerTime = prayerDateTime;
          break;
        }
      } catch (e) {
        print('Error parsing prayer time: $e for prayer: $prayer, time: ${prayerTimes[prayer]}');
        continue; // Skip this prayer if there's a parsing error
      }
    }
    
    // If no prayer is found today (after current time), find the first prayer tomorrow
    if (nextPrayer.isEmpty) {
      nextPrayer = 'Fajr';
      try {
        String timeString = prayerTimes[nextPrayer]!;
        
        // Extract only the time part before timezone if present
        String timeOnly = timeString;
        if (timeString.contains('(')) {
          timeOnly = timeString.substring(0, timeString.indexOf('(')).trim();
        }
        
        List<String> parts = timeOnly.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          
          // Set time for tomorrow's Fajr
          nextPrayerTime = DateTime(
            now.year, now.month, now.day, hour, minute).add(const Duration(days: 1));
        } else {
          // Fallback if parsing fails
          nextPrayerTime = now.add(const Duration(days: 1));
        }
      } catch (e) {
        print('Error parsing Fajr time for tomorrow: $e');
        // Fallback
        nextPrayerTime = now.add(const Duration(days: 1));
      }
    }
    
    // Calculate time difference
    Duration difference = nextPrayerTime!.difference(now);
    String timeUntil = _formatDuration(difference);
    
    return {
      'name': nextPrayer,
      'time': nextPrayerTime,
      'timeUntil': timeUntil,
    };
  }
  
  // Format duration for display
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
  
  // Update notification settings and reschedule notifications
  Future<void> updateNotificationSettings({
    bool? enabled,
    int? minutesBefore,
    Map<String, bool>? enabledPrayers,
    BuildContext? context,
  }) async {
    bool settingsChanged = false;
    
    // Update notification enabled status if provided
    if (enabled != null && enabled != _settingsProvider.notificationsEnabled) {
      await _settingsProvider.setNotificationsEnabled(enabled);
      settingsChanged = true;
    }
    
    // Update minutes before if provided
    if (minutesBefore != null && minutesBefore != _settingsProvider.notificationMinutesBefore) {
      await _settingsProvider.setNotificationMinutesBefore(minutesBefore);
      settingsChanged = true;
    }
    
    // Update enabled prayers if provided
    if (enabledPrayers != null) {
      if (enabledPrayers['fajr'] != null && 
          enabledPrayers['fajr'] != _settingsProvider.fajrNotificationsEnabled) {
        await _settingsProvider.setFajrNotificationsEnabled(enabledPrayers['fajr']!);
        settingsChanged = true;
      }
      
      if (enabledPrayers['dhuhr'] != null && 
          enabledPrayers['dhuhr'] != _settingsProvider.dhuhrNotificationsEnabled) {
        await _settingsProvider.setDhuhrNotificationsEnabled(enabledPrayers['dhuhr']!);
        settingsChanged = true;
      }
      
      if (enabledPrayers['asr'] != null && 
          enabledPrayers['asr'] != _settingsProvider.asrNotificationsEnabled) {
        await _settingsProvider.setAsrNotificationsEnabled(enabledPrayers['asr']!);
        settingsChanged = true;
      }
      
      if (enabledPrayers['maghrib'] != null && 
          enabledPrayers['maghrib'] != _settingsProvider.maghribNotificationsEnabled) {
        await _settingsProvider.setMaghribNotificationsEnabled(enabledPrayers['maghrib']!);
        settingsChanged = true;
      }
      
      if (enabledPrayers['isha'] != null && 
          enabledPrayers['isha'] != _settingsProvider.ishaNotificationsEnabled) {
        await _settingsProvider.setIshaNotificationsEnabled(enabledPrayers['isha']!);
        settingsChanged = true;
      }
    }
    
    // Reschedule notifications if settings changed
    if (settingsChanged) {
      await scheduleNotificationsForToday(context);
    }
  }
} 