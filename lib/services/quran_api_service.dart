import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran.dart';

class QuranApiService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  
  // Fetch the list of all surahs
  Future<List<Surah>> getSurahs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/surah'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['status'] == 'OK') {
          final List<dynamic> surahsJson = data['data'];
          return surahsJson.map((json) => Surah.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load surahs: ${data['status']}');
        }
      } else {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching surahs: $e');
      throw Exception('Error fetching surahs: $e');
    }
  }

  // Fetch a specific surah by number with a specific edition
  Future<SurahDetail> getSurah(int surahNumber, String edition) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw Exception('Invalid surah number. Must be between 1 and 114.');
    }
    
    try {
      print('Fetching surah $surahNumber from edition $edition');
      final response = await http.get(Uri.parse('$_baseUrl/surah/$surahNumber/$edition'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['status'] == 'OK') {
          // Create the SurahDetail from the API response
          SurahDetail surahDetail = SurahDetail.fromJson(data['data']);
          
          // Process the first ayah to separate Bismillah if needed
          _processBismillah(surahDetail);
          
          return surahDetail;
        } else {
          // If the specific edition fails, try fallback editions
          if (edition != 'quran-uthmani' && edition != 'en.asad') {
            print('Edition $edition not found. Trying fallback edition.');
            // If it was a translation request, try Asad's translation
            if (edition != 'quran-uthmani') {
              return getSurah(surahNumber, 'en.asad');
            } else {
              // If it was the Arabic text, this is a serious error
              throw Exception('Failed to load Arabic text: ${data['status']}');
            }
          }
          throw Exception('Failed to load surah: ${data['status']}');
        }
      } else {
        // If the specific edition fails, try fallback editions
        if (edition != 'quran-uthmani' && edition != 'en.asad' && response.statusCode == 404) {
          print('Edition $edition not found (404). Trying fallback edition.');
          // If it was a translation request, try Asad's translation
          if (edition != 'quran-uthmani') {
            return getSurah(surahNumber, 'en.asad');
          } else {
            // If it was the Arabic text, this is a serious error
            throw Exception('Failed to load Arabic text: ${response.statusCode}');
          }
        }
        throw Exception('Failed to load surah: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching surah: $e');
      throw Exception('Error fetching surah: $e');
    }
  }

  // Helper method to process Bismillah in the first ayah of surahs
  void _processBismillah(SurahDetail surah) {
    // We don't need to process Al-Fatihah or At-Tawbah
    if (surah.number == 1 || surah.number == 9 || surah.ayahs.isEmpty) {
      return;
    }
    
    // Get the first ayah
    Ayah firstAyah = surah.ayahs[0];
    String text = firstAyah.text;
    
    // Debug the first ayah text
    print('First ayah of Surah ${surah.number} (${surah.englishName}): $text');
    
    // For Arabic Quran text:
    if (surah.isArabicEdition()) {
      // Check for the Bismillah
      if (text.contains('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ')) {
        // For Surah Al-Baqarah (2), we know it's followed by Alif Lam Meem
        if (surah.number == 2 && text.contains('الۤمۤ')) {
          // Insert a newline after Bismillah to separate it
          String newText = text.replaceFirst('ٱلرَّحِیمِ', 'ٱلرَّحِیمِ\n');
          surah.ayahs[0] = Ayah(
            number: firstAyah.number,
            text: newText,
            numberInSurah: firstAyah.numberInSurah,
            juz: firstAyah.juz,
            page: firstAyah.page,
            sajda: firstAyah.sajda,
          );
          print('Processed first ayah to include newline after Bismillah');
        } else {
          // For other surahs, try a more general approach
          // Find the end of Bismillah and add a newline there
          final int bismillahEndIndex = text.indexOf('ٱلرَّحِیمِ') + 'ٱلرَّحِیمِ'.length;
          if (bismillahEndIndex < text.length) {
            String newText = text.substring(0, bismillahEndIndex) + '\n' + text.substring(bismillahEndIndex);
            surah.ayahs[0] = Ayah(
              number: firstAyah.number,
              text: newText,
              numberInSurah: firstAyah.numberInSurah,
              juz: firstAyah.juz,
              page: firstAyah.page,
              sajda: firstAyah.sajda,
            );
            print('Processed first ayah to include newline after Bismillah (general)');
          }
        }
      }
    } 
    // For translation text, we may need to remove "In the name of Allah..." from first ayah
    else if (surah.edition != 'quran-uthmani' && !surah.edition.startsWith('ar.')) {
      // Common Bismillah phrases in translations (these may vary by translation)
      final List<String> bismillahPhrases = [
        'In the name of Allah',
        'In the Name of Allah',
        'In the name of God',
        'In the Name of God',
        'In the name of',
        'Au nom d\'Allah',
        'Im Namen',
        'En el nombre',
        'Bismillah',
      ];
      
      // If first ayah starts with any of these phrases, it likely includes Bismillah
      bool hasBismillah = false;
      for (final phrase in bismillahPhrases) {
        if (text.startsWith(phrase)) {
          hasBismillah = true;
          break;
        }
      }
      
      // If it seems to have Bismillah, try to find where the actual ayah starts
      if (hasBismillah) {
        // Look for phrases that likely mark the end of Bismillah
        final List<String> endMarkers = ['. ', '.\n', '! ', '? '];
        int endPos = -1;
        
        for (final marker in endMarkers) {
          if (text.contains(marker)) {
            endPos = text.indexOf(marker) + marker.length - 1; // include the period but not the space
            break;
          }
        }
        
        // If we found what seems to be the end of Bismillah
        if (endPos > 0) {
          // Keep only the text after Bismillah
          String newText = text.substring(endPos + 1).trim();
          
          // Update the ayah if we found content after Bismillah
          if (newText.isNotEmpty) {
            surah.ayahs[0] = Ayah(
              number: firstAyah.number,
              text: newText,
              numberInSurah: firstAyah.numberInSurah,
              juz: firstAyah.juz,
              page: firstAyah.page,
              sajda: firstAyah.sajda,
            );
            print('Removed Bismillah from translation of first ayah');
          }
        }
      }
    }
  }

  // Fetch available editions by language
  Future<List<QuranEdition>> getEditions(String language) async {
    try {
      // Always include format=text to get text editions only
      final String url = language.isEmpty 
          ? '$_baseUrl/edition?format=text&type=translation' 
          : '$_baseUrl/edition/language/$language?format=text&type=translation';
          
      print('Fetching editions from: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['status'] == 'OK') {
          final List<dynamic> editionsJson = data['data'];
          
          if (editionsJson.isEmpty) {
            print('No editions found for language: $language');
          }
          
          return editionsJson.map((json) => QuranEdition.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load editions: ${data['status']}');
        }
      } else {
        throw Exception('Failed to load editions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching editions: $e');
      throw Exception('Error fetching editions: $e');
    }
  }

  // Get audio recitation for a surah
  Future<String> getAudioUrl(int surahNumber, String edition) {
    // For audio recitations, we're just returning the URL directly
    // The client can then use this URL with an audio player
    return Future.value('$_baseUrl/surah/$surahNumber/$edition');
  }
} 