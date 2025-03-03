import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../providers/prayer_provider.dart';
import '../models/prayer_time.dart';
import '../localizations/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    // Initialize provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
      provider.initialize().then((_) {
        // Ensure notifications are scheduled with proper context
        if (provider.currentPrayerTime != null) {
          provider.scheduleNotificationsForToday(context);
        }
      });
    });
    
    // Start timer to update countdown and current time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'nav_prayer_times')),
        centerTitle: true,
      ),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }
          
          if (provider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.loadTodayPrayerTimes(),
                    child: Text(t(context, 'retry')),
                  ),
                ],
              ),
            );
          }
          
          if (provider.currentPrayerTime == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t(context, 'no_prayer_times_available'),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.fetchDailyPrayerTimes(context),
                    child: Text(t(context, 'load_prayer_times')),
                  ),
                ],
              ),
            );
          }
          
          return Stack(
            children: [
              _buildPrayerTimesView(provider.currentPrayerTime!, provider.locationName),
              if (provider.isBackgroundLoading)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t(context, 'syncing_yearly_data'),
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrayerTimesView(PrayerTime prayerTime, String locationName) {
    final prayerTimesMap = _getPrayerTimesMap(prayerTime);
    final nextPrayerInfo = _getNextPrayer(prayerTimesMap);
    final nextPrayerName = nextPrayerInfo['name'];
    final timeUntilNextPrayer = nextPrayerInfo['timeUntil'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateAndLocationCard(prayerTime, locationName),
          const SizedBox(height: 20),
          _buildNextPrayerCard(nextPrayerName!, prayerTimesMap[nextPrayerName]!, timeUntilNextPrayer!),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Display remaining prayers in order from next prayer
          ..._buildRemainingPrayerCards(prayerTimesMap, nextPrayerName),
        ],
      ),
    );
  }
  
  Widget _buildNextPrayerCard(String name, String time, String timeUntil) {
    IconData icon = _getPrayerIcon(name);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Convert time from 24-hour to 12-hour format if needed
    String displayTime = _formatTimeDisplay(time);
    
    // Translate prayer name
    Map<String, String> prayerNameTranslation = {
      'Fajr': t(context, 'fajr'),
      'Sunrise': t(context, 'sunrise'),
      'Dhuhr': t(context, 'dhuhr'),
      'Asr': t(context, 'asr'),
      'Maghrib': t(context, 'maghrib'),
      'Isha': t(context, 'isha'),
    };
    
    String translatedName = prayerNameTranslation[name] ?? name;
    
    return Card(
      color: colorScheme.primaryContainer.withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              t(context, 'next_prayer'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, size: 36, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translatedName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              displayTime,
                              style: textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    timeUntil,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRemainingPrayerCards(Map<String, String> prayerTimes, String nextPrayer) {
    List<Widget> cards = [];
    List<String> prayerNames = [
      t(context, 'fajr'), 
      t(context, 'sunrise'), 
      t(context, 'dhuhr'), 
      t(context, 'asr'), 
      t(context, 'maghrib'), 
      t(context, 'isha')
    ];
    
    // Map prayer names to API keys for lookup
    Map<String, String> prayerNameToKey = {
      t(context, 'fajr'): 'Fajr',
      t(context, 'sunrise'): 'Sunrise',
      t(context, 'dhuhr'): 'Dhuhr',
      t(context, 'asr'): 'Asr',
      t(context, 'maghrib'): 'Maghrib',
      t(context, 'isha'): 'Isha',
    };
    
    String nextPrayerTranslated = prayerNameToKey.entries
        .firstWhere((entry) => entry.value == nextPrayer)
        .key;
    
    // Reorder prayer names to start from the next prayer
    int nextIndex = prayerNames.indexOf(nextPrayerTranslated);
    List<String> reorderedNames = [
      ...prayerNames.sublist(nextIndex + 1),
      ...prayerNames.sublist(0, nextIndex)
    ];
    
    // Build cards for remaining prayers
    for (String name in reorderedNames) {
      String apiKey = prayerNameToKey[name]!;
      cards.add(_buildPrayerTimeCard(name, prayerTimes[apiKey]!, _getPrayerIcon(apiKey)));
    }
    
    return cards;
  }

  Widget _buildPrayerTimeCard(String name, String time, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Convert time from 24-hour to 12-hour format if needed
    String displayTime = _formatTimeDisplay(time);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              displayTime,
              style: textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndLocationCard(PrayerTime prayerTime, String locationName) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Get current locale
    final String currentLocale = Localizations.localeOf(context).languageCode;
    
    // Format the current date for display with proper locale
    String formattedDate;
    
    // Special handling for Japanese locale
    if (currentLocale == 'ja') {
      final now = DateTime.now();
      formattedDate = DateFormat.yMMMMEEEEd(currentLocale).format(now);
    } else {
      formattedDate = DateFormat('EEEE, d MMMM y', currentLocale).format(DateTime.now());
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    formattedDate,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Show Hijri date if available
            if (prayerTime.hijriDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _getFormattedHijriDate(prayerTime),
                  style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    locationName.isEmpty ? t(context, 'current_location') : locationName,
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Custom method to format Hijri date with our own standardized month names
  String _getFormattedHijriDate(PrayerTime prayerTime) {
    // Get the Hijri month name based on the month number or name
    String monthName = _getHijriMonthName(prayerTime.hijriMonth);
    
    // Format the date using our standard month name
    // Format: "DD Monthname YYYY"
    return '${prayerTime.hijriDay} $monthName ${prayerTime.hijriYear}';
  }
  
  // Map Hijri month number/name to standard month name without special characters
  String _getHijriMonthName(String monthInput) {
    final List<String> hijriMonths = [
      'Muharram',       // 1
      'Safar',          // 2
      'Rabi al-Awwal',  // 3
      'Rabi al-Thani',  // 4
      'Jumada al-Awwal', // 5
      'Jumada al-Thani', // 6
      'Rajab',          // 7
      'Shaban',         // 8
      'Ramadan',        // 9
      'Shawwal',        // 10
      'Dhu al-Qadah',   // 11
      'Dhu al-Hijjah',  // 12
    ];
    
    // First try to parse as integer (month number)
    try {
      int monthNumber = int.parse(monthInput);
      if (monthNumber >= 1 && monthNumber <= 12) {
        return hijriMonths[monthNumber - 1];
      }
    } catch (e) {
      // Not a number, treat as month name string
      // Continue to name-based mapping below
    }
    
    // Map special character month names to standard ones
    Map<String, String> monthNameMap = {
      'Muḥarram': 'Muharram',
      'Ṣafar': 'Safar',
      'Rabīʿ al-Awwal': 'Rabi al-Awwal',
      'Rabī al-Awwal': 'Rabi al-Awwal',
      'Rabīʿ ath-Thānī': 'Rabi al-Thani',
      'Rabī al-Thani': 'Rabi al-Thani',
      'Jumādá al-Ūlá': 'Jumada al-Awwal',
      'Jumādá al-Ākhirah': 'Jumada al-Thani',
      'Rajab': 'Rajab',
      'Shaʿbān': 'Shaban',
      'Sha\'ban': 'Shaban',
      'Ramaḍān': 'Ramadan',
      'Ramadan': 'Ramadan',
      'Shawwāl': 'Shawwal',
      'Dhū al-Qaʿdah': 'Dhu al-Qadah',
      'Dhū al-Ḥijjah': 'Dhu al-Hijjah'
    };
    
    // Check if the input month name is in our mapping
    if (monthNameMap.containsKey(monthInput)) {
      return monthNameMap[monthInput]!;
    }
    
    // If we can't map it, return the input as is
    return monthInput;
  }

  // Utility methods
  Map<String, String> _getPrayerTimesMap(PrayerTime prayerTime) {
    return {
      'Fajr': prayerTime.fajr,
      'Sunrise': prayerTime.sunrise,
      'Dhuhr': prayerTime.dhuhr,
      'Asr': prayerTime.asr,
      'Maghrib': prayerTime.maghrib,
      'Isha': prayerTime.isha,
    };
  }
  
  IconData _getPrayerIcon(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.nights_stay;
      case 'Sunrise':
        return Icons.wb_sunny_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.sunny_snowing;
      case 'Maghrib':
        return Icons.wb_twilight;
      case 'Isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
  
  String _formatTimeDisplay(String time24) {
    try {
      // Check if the time string contains timezone information in parentheses
      String timeOnly = time24;
      if (time24.contains('(')) {
        timeOnly = time24.substring(0, time24.indexOf('(')).trim();
      }
      
      // Parse the 24-hour time
      List<String> parts = timeOnly.split(':');
      if (parts.length < 2) {
        return time24; // Return original if format is unexpected
      }
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      // Convert to 12-hour format
      String period = (hour >= 12) ? t(context, 'pm') : t(context, 'am');
      hour = (hour > 12) ? hour - 12 : hour;
      hour = (hour == 0) ? 12 : hour; // Handle midnight
      
      // Format as 12-hour time
      String formatted = '$hour:${minute.toString().padLeft(2, '0')} $period';
      
      // Add timezone if present in original
      if (time24.contains('(')) {
        String timezone = time24.substring(time24.indexOf('('));
        formatted += ' $timezone';
      }
      
      return formatted;
    } catch (e) {
      print('Error formatting time: $e for input: $time24');
      return time24; // Return original if parsing fails
    }
  }
  
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
  
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours} ${t(context, 'hour')} ${minutes > 0 ? '${minutes} ${t(context, 'minute')}' : ''}';
    } else {
      return '${minutes} ${t(context, 'minute')}';
    }
  }
} 