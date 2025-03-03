import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/prayer_settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/quran_provider.dart';
import 'screens/navigation_container.dart';
import 'models/prayer_time.dart';
import 'theme/app_theme.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localizations/app_localizations.dart';

void testHijriDateParsing() {
  // Sample response data from the API
  final Map<String, dynamic> apiResponse = {
    "code": 200,
    "status": "OK",
    "data": {
      "timings": {
        "Fajr": "06:03",
        "Sunrise": "08:06",
        "Dhuhr": "12:04",
        "Asr": "13:44",
        "Sunset": "16:03",
        "Maghrib": "16:03",
        "Isha": "17:59",
        "Imsak": "05:53",
        "Midnight": "00:04",
        "Firstthird": "21:24",
        "Lastthird": "02:45"
      },
      "date": {
        "readable": "01 Jan 2025",
        "timestamp": "1735714800",
        "hijri": {
          "date": "01-07-1446",
          "format": "DD-MM-YYYY",
          "day": "1",
          "weekday": {
            "en": "Al Arba'a",
            "ar": "الاربعاء"
          },
          "month": {
            "number": 7,
            "en": "Rajab",
            "ar": "رَجَب",
            "days": 30
          },
          "year": "1446",
          "designation": {
            "abbreviated": "AH",
            "expanded": "Anno Hegirae"
          },
          "holidays": [
            "Beginning of the holy months"
          ]
        },
        "gregorian": {
          "date": "01-01-2025",
          "format": "DD-MM-YYYY",
          "day": "01",
          "weekday": {
            "en": "Wednesday"
          },
          "month": {
            "number": 1,
            "en": "January"
          },
          "year": "2025",
          "designation": {
            "abbreviated": "AD",
            "expanded": "Anno Domini"
          }
        }
      },
      "meta": {
        "latitude": 51.5194682,
        "longitude": -0.1360365,
        "timezone": "UTC",
        "method": {
          "id": 3,
          "name": "Muslim World League",
          "params": {
            "Fajr": 18,
            "Isha": 17
          }
        }
      }
    }
  };

  try {
    // Convert the API response to a PrayerTime object
    final prayerTime = PrayerTime.fromJson(apiResponse['data'], 1);
    
    // Print the resulting PrayerTime fields to verify Hijri information is extracted correctly
    print('Hijri Date: ${prayerTime.hijriDate}');
    print('Hijri Day: ${prayerTime.hijriDay}');
    print('Hijri Weekday: ${prayerTime.hijriWeekday}');
    print('Hijri Month: ${prayerTime.hijriMonth}');
    print('Hijri Year: ${prayerTime.hijriYear}');
    print('Formatted Hijri Date: ${prayerTime.getFormattedHijriDate()}');
    
    // Verification successful
    print('Hijri date extraction test completed successfully!');
  } catch (e) {
    print('Error parsing hijri date: $e');
  }
}

Future<void> initApp() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Set preferred orientations (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void main() async {
  // Initialize app
  await initApp();
  
  // Test hijri date parsing
  testHijriDateParsing();
  
  // Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Create the settings provider first since prayer provider depends on it
        ChangeNotifierProvider(create: (_) => PrayerSettingsProvider()),
        // Create prayer provider with dependency injection
        ChangeNotifierProxyProvider<PrayerSettingsProvider, PrayerTimesProvider>(
          create: (context) => PrayerTimesProvider(Provider.of<PrayerSettingsProvider>(context, listen: false)),
          update: (context, settingsProvider, previous) => previous ?? PrayerTimesProvider(settingsProvider),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'Muslim Essentials',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const NavigationContainer(),
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'), // English
              Locale('id'), // Indonesian
              Locale('ja'), // Japanese
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
