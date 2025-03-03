import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerSettingsProvider extends ChangeNotifier {
  // Keys for shared preferences
  static const String _calculationMethodKey = 'calculation_method';
  static const String _juristicMethodKey = 'juristic_method';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationMinutesBeforeKey = 'notification_minutes_before';
  static const String _fajrNotificationsEnabledKey = 'fajr_notifications_enabled';
  static const String _dhuhrNotificationsEnabledKey = 'dhuhr_notifications_enabled';
  static const String _asrNotificationsEnabledKey = 'asr_notifications_enabled';
  static const String _maghribNotificationsEnabledKey = 'maghrib_notifications_enabled';
  static const String _ishaNotificationsEnabledKey = 'isha_notifications_enabled';
  
  // Default values
  static const int defaultCalculationMethod = -1; // Automatic (uses closest authority)
  static const int defaultJuristicMethod = 0;    // Standard (Shafi, Hanbali, Maliki)
  static const bool defaultNotificationsEnabled = true;
  static const int defaultNotificationMinutesBefore = 10;
  static const bool defaultPrayerNotificationsEnabled = true;
  
  // Available calculation methods
  static const Map<int, String> calculationMethods = {
    -1: 'Automatic (closest authority)',
    0: 'Jafari / Shia Ithna-Ashari',
    1: 'University of Islamic Sciences, Karachi',
    2: 'Islamic Society of North America',
    3: 'Muslim World League',
    4: 'Umm Al-Qura University, Makkah',
    5: 'Egyptian General Authority of Survey',
    7: 'Institute of Geophysics, University of Tehran',
    8: 'Gulf Region',
    9: 'Kuwait',
    10: 'Qatar',
    11: 'Majlis Ugama Islam Singapura, Singapore',
    12: 'Union Organization Islamic de France',
    13: 'Diyanet İşleri Başkanlığı, Turkey',
    14: 'Spiritual Administration of Muslims of Russia',
    15: 'Moonsighting Committee Worldwide',
    16: 'Dubai, UAE (experimental)',
    17: 'Jabatan Kemajuan Islam Malaysia (JAKIM)',
    18: 'Tunisia',
    19: 'Algeria',
    20: 'KEMENAG - Kementerian Agama Republik Indonesia',
    21: 'Morocco',
    22: 'Comunidade Islamica de Lisboa',
    23: 'Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan',
  };
  
  // Available juristic methods for Asr calculation
  static const Map<int, String> juristicMethods = {
    0: 'Standard (Shafi, Hanbali, Maliki)',
    1: 'Hanafi',
  };
  
  // Current settings
  int _calculationMethod = defaultCalculationMethod;
  int _juristicMethod = defaultJuristicMethod;
  bool _notificationsEnabled = defaultNotificationsEnabled;
  int _notificationMinutesBefore = defaultNotificationMinutesBefore;
  bool _fajrNotificationsEnabled = defaultPrayerNotificationsEnabled;
  bool _dhuhrNotificationsEnabled = defaultPrayerNotificationsEnabled;
  bool _asrNotificationsEnabled = defaultPrayerNotificationsEnabled;
  bool _maghribNotificationsEnabled = defaultPrayerNotificationsEnabled;
  bool _ishaNotificationsEnabled = defaultPrayerNotificationsEnabled;
  bool _initialized = false;
  
  // Getters
  int get calculationMethod => _calculationMethod;
  int get juristicMethod => _juristicMethod;
  bool get isInitialized => _initialized;
  
  // Notification getters
  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationMinutesBefore => _notificationMinutesBefore;
  bool get fajrNotificationsEnabled => _fajrNotificationsEnabled;
  bool get dhuhrNotificationsEnabled => _dhuhrNotificationsEnabled;
  bool get asrNotificationsEnabled => _asrNotificationsEnabled;
  bool get maghribNotificationsEnabled => _maghribNotificationsEnabled;
  bool get ishaNotificationsEnabled => _ishaNotificationsEnabled;
  
  // Get prayer-specific notification settings as a map
  Map<String, bool> get enabledPrayerNotifications => {
    'fajr': _fajrNotificationsEnabled,
    'dhuhr': _dhuhrNotificationsEnabled,
    'asr': _asrNotificationsEnabled,
    'maghrib': _maghribNotificationsEnabled,
    'isha': _ishaNotificationsEnabled,
  };
  
  // Initialize provider
  Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load calculation method
    _calculationMethod = prefs.getInt(_calculationMethodKey) ?? defaultCalculationMethod;
    
    // Load juristic method
    _juristicMethod = prefs.getInt(_juristicMethodKey) ?? defaultJuristicMethod;
    
    // Load notification settings
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? defaultNotificationsEnabled;
    _notificationMinutesBefore = prefs.getInt(_notificationMinutesBeforeKey) ?? defaultNotificationMinutesBefore;
    _fajrNotificationsEnabled = prefs.getBool(_fajrNotificationsEnabledKey) ?? defaultPrayerNotificationsEnabled;
    _dhuhrNotificationsEnabled = prefs.getBool(_dhuhrNotificationsEnabledKey) ?? defaultPrayerNotificationsEnabled;
    _asrNotificationsEnabled = prefs.getBool(_asrNotificationsEnabledKey) ?? defaultPrayerNotificationsEnabled;
    _maghribNotificationsEnabled = prefs.getBool(_maghribNotificationsEnabledKey) ?? defaultPrayerNotificationsEnabled;
    _ishaNotificationsEnabled = prefs.getBool(_ishaNotificationsEnabledKey) ?? defaultPrayerNotificationsEnabled;
    
    _initialized = true;
    notifyListeners();
  }
  
  // Save calculation method
  Future<void> setCalculationMethod(int method) async {
    if (!calculationMethods.containsKey(method)) {
      throw Exception('Invalid calculation method: $method');
    }
    
    _calculationMethod = method;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calculationMethodKey, method);
  }
  
  // Save juristic method
  Future<void> setJuristicMethod(int method) async {
    if (!juristicMethods.containsKey(method)) {
      throw Exception('Invalid juristic method: $method');
    }
    
    _juristicMethod = method;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_juristicMethodKey, method);
  }
  
  // Save notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }
  
  // Save notification minutes before
  Future<void> setNotificationMinutesBefore(int minutes) async {
    if (minutes < 0) {
      throw Exception('Minutes before prayer must be non-negative');
    }
    
    _notificationMinutesBefore = minutes;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationMinutesBeforeKey, minutes);
  }
  
  // Save prayer-specific notification settings
  Future<void> setFajrNotificationsEnabled(bool enabled) async {
    _fajrNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fajrNotificationsEnabledKey, enabled);
  }
  
  Future<void> setDhuhrNotificationsEnabled(bool enabled) async {
    _dhuhrNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dhuhrNotificationsEnabledKey, enabled);
  }
  
  Future<void> setAsrNotificationsEnabled(bool enabled) async {
    _asrNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_asrNotificationsEnabledKey, enabled);
  }
  
  Future<void> setMaghribNotificationsEnabled(bool enabled) async {
    _maghribNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_maghribNotificationsEnabledKey, enabled);
  }
  
  Future<void> setIshaNotificationsEnabled(bool enabled) async {
    _ishaNotificationsEnabled = enabled;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ishaNotificationsEnabledKey, enabled);
  }
  
  // Get calculation method name
  String getCalculationMethodName(int method) {
    return calculationMethods[method] ?? 'Unknown Method';
  }
  
  // Get juristic method name
  String getJuristicMethodName(int method) {
    return juristicMethods[method] ?? 'Unknown Method';
  }
  
  // Get current calculation method name
  String get currentCalculationMethodName => 
      getCalculationMethodName(_calculationMethod);
  
  // Get current juristic method name
  String get currentJuristicMethodName => 
      getJuristicMethodName(_juristicMethod);
} 