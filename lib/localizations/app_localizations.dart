import 'package:flutter/material.dart';

import 'translations/en_translations.dart';
import 'translations/id_translations.dart';
import 'translations/ja_translations.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  late Map<String, String> _localizedStrings;
  
  Future<bool> load() async {
    if (locale.languageCode == 'id') {
      _localizedStrings = idTranslations;
    } else if (locale.languageCode == 'ja') {
      _localizedStrings = jaTranslations;
    } else {
      _localizedStrings = enTranslations;
    }
    return true;
  }
  
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
  
  String translateWithArgs(String key, List<dynamic> args) {
    String translated = translate(key);
    
    for (var i = 0; i < args.length; i++) {
      translated = translated.replaceFirst('{}', args[i].toString());
    }
    
    return translated;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'id', 'ja'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}

// Helper function to easily access translations
String t(BuildContext context, String key, {List<dynamic>? args}) {
  if (args != null && args.isNotEmpty) {
    return AppLocalizations.of(context).translateWithArgs(key, args);
  }
  return AppLocalizations.of(context).translate(key);
} 