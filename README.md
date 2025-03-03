# Muslim Essentials

A Flutter application that provides essential Islamic tools including prayer times based on the user's location, Qibla direction, and more.

## Features

- **Prayer Times**
  - Gets user's current GPS location
  - Fast loading with quick access to today's prayer times
  - Fetches prayer times for an entire year from Al Adhan API in the background
  - Uses closest regional authority for prayer calculation method
  - Saves prayer times locally using SQLite database
  - Automatically updates prayer times with new location data
  
- **Qibla Compass**
  - Uses your device's location to determine the precise Qibla direction
  - Displays a compass that rotates with your device's orientation
  - Shows the exact degrees to Qibla
  - Works worldwide

- **Quran Reader**
  - Browse and read the complete Quran
  - Multiple translation options
  - Save and track your last reading position
  - Beautiful Arabic text display

- **Settings and Preferences**
  - Light and dark theme options
  - Multiple languages (English, Indonesian, Japanese)
  - Prayer notification settings
  - Location updates

- **User Experience**
  - Beautiful Material Design UI
  - Intuitive navigation with Prayer Times, Quran, Qibla, and Settings sections

## Technologies Used

- Flutter for cross-platform mobile app development
- Provider for state management
- SQLite (via sqflite) for local database storage
- Geolocator for accessing device location
- HTTP for API requests to Al Adhan API
- Intl for date formatting
- flutter_compass for Qibla direction functionality

## Getting Started

1. Ensure you have Flutter installed on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect your device or emulator
5. Run `flutter run` to start the app

## Required Permissions

The app requires the following permissions:
- Location (to determine your current position for prayer times and Qibla direction)
- Sensor access (for compass functionality)
- Internet connection (to fetch data from APIs)

## How to Use

### Prayer Times
When you first open the app, it will request permission to access your location. Once granted, tap the "Load Prayer Times" button to:

1. Quickly download today's and tomorrow's prayer times based on your current location
2. Display today's prayer times immediately
3. Download the full year's data in the background for offline access

The app displays the current day's prayer times including Fajr, Sunrise, Dhuhr, Asr, Maghrib, and Isha.

### Qibla Compass
1. Navigate to the Qibla screen
2. Hold your device flat and level
3. The compass will point to the direction of the Kaaba in Mecca
4. If the compass needs calibration, rotate your device in a figure-8 pattern

### Navigation
Use the bottom navigation bar to access different sections:
- Prayer Times: View today's prayer schedule
- Quran: Read and browse the Holy Quran (coming soon)
- Qibla: Find the direction of the Kaaba
- Settings: Configure app preferences (coming soon)

## API References

This app uses the following APIs from [Al Adhan](https://aladhan.com/):
- [Prayer Times API](https://aladhan.com/prayer-times-api) - For accurate prayer times based on geographical coordinates
- [Qibla API](https://aladhan.com/qibla-api) - For determining the direction of Qibla

## License

This project is open source and available under the MIT License.
