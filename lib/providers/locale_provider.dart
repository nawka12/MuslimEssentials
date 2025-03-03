import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final String _prefsKey = 'language_code';

  LocaleProvider() {
    _loadLocaleFromPrefs();
  }

  Locale get locale => _locale;

  bool get isEnglish => _locale.languageCode == 'en';
  bool get isIndonesian => _locale.languageCode == 'id';
  bool get isJapanese => _locale.languageCode == 'ja';

  Future<void> _loadLocaleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_prefsKey);
    
    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
    
    notifyListeners();
  }

  Future<void> setEnglish() async {
    await setLocale(const Locale('en'));
  }

  Future<void> setIndonesian() async {
    await setLocale(const Locale('id'));
  }
  
  Future<void> setJapanese() async {
    await setLocale(const Locale('ja'));
  }
} 