import 'package:flutter/material.dart';

class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  Surah({
    required this.number,
    required this.name, 
    required this.englishName, 
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      numberOfAyahs: json['numberOfAyahs'],
      revelationType: json['revelationType'],
    );
  }
}

class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int page;
  final String? sajda; // Some ayahs have sajda information

  Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    this.sajda,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'],
      text: json['text'],
      numberInSurah: json['numberInSurah'],
      juz: json['juz'],
      page: json['page'],
      sajda: json['sajda'] != null ? 'Yes' : null,
    );
  }
}

class QuranEdition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;
  final String format;
  final String type;
  final String direction;

  QuranEdition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
    required this.format,
    required this.type,
    required this.direction,
  });

  factory QuranEdition.fromJson(Map<String, dynamic> json) {
    // Default to RTL for Arabic, LTR for others
    String direction = 'ltr';
    if (json['language'] == 'ar') {
      direction = 'rtl';
    }
    
    return QuranEdition(
      identifier: json['identifier'],
      language: json['language'],
      name: json['name'],
      englishName: json['englishName'],
      format: json['format'],
      type: json['type'],
      direction: json['direction'] ?? direction,
    );
  }
  
  // Helper to determine text direction
  TextDirection getTextDirection() {
    return direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
  }
}

class SurahDetail {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  List<Ayah> ayahs;  // Removed 'final' to make it mutable
  final String edition;

  SurahDetail({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahs,
    required this.edition,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    return SurahDetail(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      revelationType: json['revelationType'],
      ayahs: (json['ayahs'] as List)
          .map((ayah) => Ayah.fromJson(ayah))
          .toList(),
      edition: json['edition']['identifier'] ?? '',
    );
  }
  
  // Helper to determine if this is the Arabic edition
  bool isArabicEdition() {
    return edition == 'quran-uthmani' || edition.startsWith('ar.');
  }
} 