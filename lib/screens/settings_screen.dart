import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../localizations/app_localizations.dart';
import 'notification_settings_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = Provider.of<PrayerSettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'nav_settings')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsCategory(t(context, 'prayer_settings'), textTheme),
          _buildSettingsTile(
            t(context, 'update_location'),
            t(context, 'refresh_location_desc'),
            Icons.location_on_outlined,
            () => _updateLocation(),
          ),
          
          const SizedBox(height: 20),
          _buildSettingsCategory(t(context, 'appearance'), textTheme),
          _buildThemeToggleTile(themeProvider, colorScheme),
          _buildSettingsTile(
            t(context, 'language'),
            localeProvider.isEnglish ? t(context, 'english') : 
            localeProvider.isIndonesian ? t(context, 'indonesian') : t(context, 'japanese'),
            Icons.language_outlined,
            () => _showLanguageDialog(localeProvider),
          ),
          
          const SizedBox(height: 20),
          _buildSettingsCategory(t(context, 'notifications'), textTheme),
          _buildSettingsTile(
            t(context, 'prayer_notifications'),
            t(context, 'prayer_notifications_desc'),
            Icons.notifications_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
            ),
          ),
          
          const SizedBox(height: 20),
          _buildSettingsCategory(t(context, 'about'), textTheme),
          _buildSettingsTile(
            t(context, 'app_version'),
            "1.0.0",
            Icons.info_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleTile(ThemeProvider themeProvider, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        secondary: Icon(
          themeProvider.isDarkMode 
              ? Icons.dark_mode
              : Icons.light_mode,
          color: colorScheme.primary,
        ),
        title: Text(t(context, 'dark_mode')),
        subtitle: Text(themeProvider.isDarkMode ? t(context, 'on') : t(context, 'off')),
        value: themeProvider.isDarkMode,
        onChanged: (_) {
          themeProvider.toggleTheme();
        },
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingsCategory(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 22),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(LocaleProvider localeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(t(context, 'english')),
              leading: Radio<String>(
                value: 'en',
                groupValue: localeProvider.locale.languageCode,
                onChanged: (value) {
                  localeProvider.setEnglish();
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                localeProvider.setEnglish();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(t(context, 'indonesian')),
              leading: Radio<String>(
                value: 'id',
                groupValue: localeProvider.locale.languageCode,
                onChanged: (value) {
                  localeProvider.setIndonesian();
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                localeProvider.setIndonesian();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(t(context, 'japanese')),
              leading: Radio<String>(
                value: 'ja',
                groupValue: localeProvider.locale.languageCode,
                onChanged: (value) {
                  localeProvider.setJapanese();
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                localeProvider.setJapanese();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(context, 'cancel')),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'coming_soon')),
        content: Text(t(context, 'coming_soon_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(context, 'ok')),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _updateLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(context, 'update_location_title')),
        content: Text(t(context, 'update_location_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLocationUpdate();
            },
            child: Text(t(context, 'update')),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _performLocationUpdate() async {
    // Get the scaffold messenger before the async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
    
    // Show loading indicator
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(t(context, 'updating_location')),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Update location and fetch new prayer times
    await provider.fetchDailyPrayerTimes(context);
    
    // Check if the widget is still mounted before showing the success message
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(t(context, 'prayer_times_updated')),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 