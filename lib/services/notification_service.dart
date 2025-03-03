import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'dart:io';
import '../models/prayer_time.dart';
import '../localizations/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  NotificationService._internal();
  
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz_init.initializeTimeZones();
      
      // Initialize notification settings
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
      
      // Updated initialization settings for iOS/macOS (Darwin)
      const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // onDidReceiveLocalNotification parameter has been removed in newer versions
      );
      
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );
      
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          // Handle notification tap
          debugPrint('Notification tapped: ${notificationResponse.payload}');
        },
      );
      
      // Request permissions for iOS/macOS
      if (Platform.isIOS || Platform.isMacOS) {
        await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        // For Android, the permissions are requested differently in newer versions
        // Using requestNotificationsPermission instead of requestPermission
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      }
      
      debugPrint('Notification service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing notification service: $e');
      debugPrint('Stack trace: $stackTrace');
      // Re-throw to allow the caller to handle the error
      rethrow;
    }
  }
  
  // Send an immediate test notification with localized text
  Future<void> showTestNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification from Muslim Essentials app'
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'prayer_times_test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: 'mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0, // notification id
      title,
      body,
      platformChannelSpecifics,
      payload: 'test_notification',
    );
    
    debugPrint('Test notification sent');
  }
  
  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Schedule a single prayer time notification
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int minutesBefore = 10,
  }) async {
    // Calculate the actual notification time (before prayer time)
    final notificationTime = scheduledTime.subtract(Duration(minutes: minutesBefore));
    
    // Skip if the notification time has already passed
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }
    
    // Notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'prayer_times_channel',
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );
    
    // Schedule notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  // Schedule notifications for a prayer time with localized content
  Future<void> schedulePrayerTimeNotifications({
    required PrayerTime prayerTime,
    required Map<String, bool> enabledPrayers,
    required int minutesBefore,
    required Map<String, String> localizedPrayerNames,
    required String Function(String prayerName, int minutes) bodyTextFormatter,
  }) async {
    // Convert date and prayer times to DateTime objects
    final date = _parseDate(prayerTime.date);
    
    // Define a map of prayer names and times
    final prayers = {
      'fajr': {
        'displayName': localizedPrayerNames['fajr'] ?? 'Fajr',
        'time': _parseTimeString(date, prayerTime.fajr),
        'enabled': enabledPrayers['fajr'] ?? false,
      },
      'dhuhr': {
        'displayName': localizedPrayerNames['dhuhr'] ?? 'Dhuhr', 
        'time': _parseTimeString(date, prayerTime.dhuhr),
        'enabled': enabledPrayers['dhuhr'] ?? false,
      },
      'asr': {
        'displayName': localizedPrayerNames['asr'] ?? 'Asr',
        'time': _parseTimeString(date, prayerTime.asr),
        'enabled': enabledPrayers['asr'] ?? false,
      },
      'maghrib': {
        'displayName': localizedPrayerNames['maghrib'] ?? 'Maghrib',
        'time': _parseTimeString(date, prayerTime.maghrib),
        'enabled': enabledPrayers['maghrib'] ?? false,
      },
      'isha': {
        'displayName': localizedPrayerNames['isha'] ?? 'Isha',
        'time': _parseTimeString(date, prayerTime.isha),
        'enabled': enabledPrayers['isha'] ?? false,
      },
    };
    
    // Schedule notifications for each enabled prayer
    for (final entry in prayers.entries) {
      final prayerName = entry.key;
      final prayerData = entry.value;
      
      if (prayerData['enabled'] == true) {
        final displayName = prayerData['displayName'] as String;
        final title = '${displayName} ' + (localizedPrayerNames['prayer'] ?? 'Prayer');
        final body = bodyTextFormatter(displayName, minutesBefore);
        final time = prayerData['time'] as DateTime;
        
        // Use a unique ID for each prayer
        final id = _getNotificationId(prayerName, date);
        
        await schedulePrayerNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: time,
          minutesBefore: minutesBefore,
        );
      }
    }
  }
  
  // Parse date string in format 'dd-MM-yyyy'
  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }
  
  // Parse time string in format 'HH:mm'
  DateTime _parseTimeString(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]), // hour
      int.parse(parts[1]), // minute
    );
  }
  
  // Generate a unique notification ID for each prayer and date combination
  int _getNotificationId(String prayerName, DateTime date) {
    // Use day of year and prayer type to create a unique ID
    final dayOfYear = int.parse('${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}');
    
    // Map prayer names to unique integers
    final prayerIds = {
      'fajr': 1,
      'dhuhr': 2,
      'asr': 3,
      'maghrib': 4,
      'isha': 5,
    };
    
    // Combine day of year and prayer ID
    return dayOfYear + (prayerIds[prayerName] ?? 0);
  }
  
  // Check if notification permissions are granted (for Android)
  Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        final bool? arePermissionsGranted = 
            await androidImplementation.areNotificationsEnabled();
        return arePermissionsGranted ?? false;
      }
    }
    
    // For iOS/macOS, we'll assume permissions are granted since they're requested at initialization
    return true;
  }
  
  // Request notification permissions
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
} 