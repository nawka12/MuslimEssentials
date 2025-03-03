import 'package:flutter/material.dart';
import '../localizations/app_localizations.dart';
import 'home_screen.dart';
import 'quran_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NavigationContainer extends StatefulWidget {
  const NavigationContainer({Key? key}) : super(key: key);

  @override
  _NavigationContainerState createState() => _NavigationContainerState();
}

class _NavigationContainerState extends State<NavigationContainer> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();
  bool _notificationsInitialized = false;
  String _notificationError = '';
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const QuranScreen(),
    const QiblaScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize notification service first thing
    _initializeNotifications();
    // Check if this is the first time app is run and request permissions
    _checkFirstRunAndRequestPermissions();
  }
  
  // Initialize notification service
  Future<void> _initializeNotifications() async {
    try {
      // Add a small delay to ensure proper initialization
      await Future.delayed(const Duration(milliseconds: 100));
      await _notificationService.initialize();
      setState(() {
        _notificationsInitialized = true;
      });
      print('Notification service initialized successfully');
    } catch (e) {
      setState(() {
        _notificationError = e.toString();
      });
      print('Error initializing notification service: $e');
      
      // If notification initialization fails, try again after a delay 
      // but only in release mode (which might be indicated by this specific error)
      if (e.toString().contains('Missing type parameter')) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!_notificationsInitialized) {
            print('Trying notification initialization again...');
            _initializeNotifications();
          }
        });
      }
    }
  }
  
  Future<void> _checkFirstRunAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('first_run') ?? true;
    
    if (isFirstRun) {
      // Set first run to false so this only runs once
      await prefs.setBool('first_run', false);
      
      // Wait for the build to complete before showing dialogs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Request location permission first
        _showLocationPermissionDialog();
      });
    }
  }
  
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'permission_required')),
        content: Text(t(context, 'location_permission_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Show notification permission dialog after location dialog is closed
              _showNotificationPermissionDialog();
            },
            child: Text(t(context, 'later')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Request location permission
              await _locationService.getCurrentPosition();
              // Show notification permission dialog after location dialog is closed
              _showNotificationPermissionDialog();
            },
            child: Text(t(context, 'grant_permission')),
          ),
        ],
      ),
    );
  }
  
  void _showNotificationPermissionDialog() {
    if (Platform.isAndroid || Platform.isIOS) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(t(context, 'permission_required')),
          content: Text(t(context, 'notification_permission_message')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(t(context, 'later')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Request notification permission
                await _notificationService.requestPermissions();
              },
              child: Text(t(context, 'grant_permission')),
            ),
          ],
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: textTheme.bodySmall,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.access_time),
              label: t(context, 'nav_prayer_times'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book),
              label: t(context, 'nav_quran'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore),
              label: t(context, 'nav_qibla'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: t(context, 'nav_settings'),
            ),
          ],
        ),
      ),
    );
  }
} 