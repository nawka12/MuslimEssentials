import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/prayer_settings_provider.dart';
import '../providers/prayer_provider.dart';
import '../services/notification_service.dart';
import '../localizations/app_localizations.dart';
import 'package:flutter/foundation.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<PrayerSettingsProvider>(context);
    final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'prayer_notifications')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Master switch for all notifications
          SwitchListTile(
            title: Text(t(context, 'enable_notifications')),
            subtitle: Text(t(context, 'receive_notifications_for_prayer_times')),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) {
              settingsProvider.setNotificationsEnabled(value);
              // Schedule notifications with proper localization context
              prayerProvider.scheduleNotificationsForToday(context);
            },
            activeColor: colorScheme.primary,
          ),
          
          const Divider(height: 32),
          
          if (settingsProvider.notificationsEnabled) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'test_notifications'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(context, 'send_a_test_notification_to_verify_that_notifications_are_working_correctly'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _sendTestNotification(context),
                        child: Text(t(context, 'send_test_notification')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Minutes before setting
            ListTile(
              title: Text(t(context, 'minutes_before_prayer')),
              subtitle: Text(t(context, 'get_notified_minutes_before_prayer_time', args: [settingsProvider.notificationMinutesBefore.toString()])),
              onTap: () => _showMinutesBeforeDialog(context),
            ),
            
            const Divider(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                t(context, 'select_prayers'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            // Individual prayer notification toggles
            SwitchListTile(
              title: Text(t(context, 'fajr')),
              subtitle: Text(t(context, 'notification_for_fajr_prayer')),
              value: settingsProvider.fajrNotificationsEnabled,
              onChanged: (value) {
                settingsProvider.setFajrNotificationsEnabled(value);
                // Schedule notifications with proper localization context
                prayerProvider.scheduleNotificationsForToday(context);
              },
              activeColor: colorScheme.primary,
            ),
            
            SwitchListTile(
              title: Text(t(context, 'dhuhr')),
              subtitle: Text(t(context, 'notification_for_dhuhr_prayer')),
              value: settingsProvider.dhuhrNotificationsEnabled,
              onChanged: (value) {
                settingsProvider.setDhuhrNotificationsEnabled(value);
                // Schedule notifications with proper localization context
                prayerProvider.scheduleNotificationsForToday(context);
              },
              activeColor: colorScheme.primary,
            ),
            
            SwitchListTile(
              title: Text(t(context, 'asr')),
              subtitle: Text(t(context, 'notification_for_asr_prayer')),
              value: settingsProvider.asrNotificationsEnabled,
              onChanged: (value) {
                settingsProvider.setAsrNotificationsEnabled(value);
                // Schedule notifications with proper localization context
                prayerProvider.scheduleNotificationsForToday(context);
              },
              activeColor: colorScheme.primary,
            ),
            
            SwitchListTile(
              title: Text(t(context, 'maghrib')),
              subtitle: Text(t(context, 'notification_for_maghrib_prayer')),
              value: settingsProvider.maghribNotificationsEnabled,
              onChanged: (value) {
                settingsProvider.setMaghribNotificationsEnabled(value);
                // Schedule notifications with proper localization context
                prayerProvider.scheduleNotificationsForToday(context);
              },
              activeColor: colorScheme.primary,
            ),
            
            SwitchListTile(
              title: Text(t(context, 'isha')),
              subtitle: Text(t(context, 'notification_for_isha_prayer')),
              value: settingsProvider.ishaNotificationsEnabled,
              onChanged: (value) {
                settingsProvider.setIshaNotificationsEnabled(value);
                // Schedule notifications with proper localization context
                prayerProvider.scheduleNotificationsForToday(context);
              },
              activeColor: colorScheme.primary,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                t(context, 'enable_notifications_to_configure_prayer_specific_settings'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showMinutesBeforeDialog(BuildContext context) {
    final settingsProvider = Provider.of<PrayerSettingsProvider>(context, listen: false);
    final prayerProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    int minutes = settingsProvider.notificationMinutesBefore;
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'minutes_before_prayer')),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t(context, 'how_many_minutes_before_prayer_time_would_you_like_to_be_notified')),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: minutes > 1 
                          ? () => setState(() => minutes--) 
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$minutes ${t(context, 'minutes')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: minutes < 60 
                          ? () => setState(() => minutes++) 
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              settingsProvider.setNotificationMinutesBefore(minutes);
              // Schedule notifications with proper localization context
              prayerProvider.scheduleNotificationsForToday(context);
              Navigator.of(context).pop();
            },
            child: Text(t(context, 'save')),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendTestNotification(BuildContext context) async {
    final notificationService = NotificationService();
    
    try {
      // Check if notification permissions are granted (on Android)
      bool permissionsGranted = true;
      if (Platform.isAndroid) {
        permissionsGranted = await notificationService.checkPermissions();
      }
      
      if (!permissionsGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(context, 'notification_permission_required')),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 5),
            ),
          );
          
          // Request permissions
          await notificationService.requestPermissions();
          return;
        }
      }
      
      // Send test notification with localized strings
      await notificationService.showTestNotification(
        title: t(context, 'test_notification'),
        body: t(context, 'send_a_test_notification_to_verify_that_notifications_are_working_correctly')
      );
      
      // Show a confirmation to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(context, 'test_notification_sent')),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(context, 'notification_test_failed')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
} 