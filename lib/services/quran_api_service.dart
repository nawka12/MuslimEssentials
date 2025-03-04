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
      print('Skipping Bismillah processing for Surah ${surah.number} (${surah.englishName})');
      return;
    }
    
    // Get the first ayah
    Ayah firstAyah = surah.ayahs[0];
    String text = firstAyah.text;
    
    // Debug the first ayah text
    print('First ayah of Surah ${surah.number} (${surah.englishName}): $text');
    
    // For Arabic Quran text:
    if (surah.isArabicEdition()) {
      // Different Unicode variations of Bismillah that might appear in the text
      final List<String> bismillahVariations = [
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ', // Common variation
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',   // Variation seen in Surah 4
        'بسم الله الرحمن الرحيم',             // Simple variation without diacritics
        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',   // Another common variation
      ];
      
      // Check if the text contains any variation of Bismillah
      bool containsBismillah = false;
      String matchedBismillah = '';
      
      for (final bismillah in bismillahVariations) {
        if (text.contains(bismillah)) {
          containsBismillah = true;
          matchedBismillah = bismillah;
          print('Found Bismillah variation in Surah ${surah.number}: $matchedBismillah');
          break;
        }
      }
      
      if (containsBismillah) {
        // Special handling for surahs that start with Arabic letters (Muqatta'at)
        // These surahs include: 2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20, 26, 27, 28, 29, 30, 31, 32, 36, 38, 40-46, 50, 68
        final List<int> muqattaatSurahs = [2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20, 26, 27, 28, 29, 30, 31, 32, 36, 38, 40, 41, 42, 43, 44, 45, 46, 50, 68];
        
        if (muqattaatSurahs.contains(surah.number)) {
          print('Special handling for Muqatta\'at Surah ${surah.number} (${surah.englishName})');
          
          // Map of known Arabic letter patterns for each surah
          final Map<int, String> arabicLetterPatterns = {
            2: 'الۤمۤ', // Al-Baqarah: Alif Lam Mim
            3: 'الۤمۤ', // Aal-i-Imraan: Alif Lam Mim
            7: 'الۤمۤصۤ', // Al-A'raf: Alif Lam Mim Sad
            10: 'الۤرۤ', // Yunus: Alif Lam Ra
            11: 'الۤرۤ', // Hud: Alif Lam Ra
            12: 'الۤرۤ', // Yusuf: Alif Lam Ra
            13: 'الۤمۤرۤ', // Ar-Ra'd: Alif Lam Mim Ra
            14: 'الۤرۤ', // Ibrahim: Alif Lam Ra
            15: 'الۤرۤ', // Al-Hijr: Alif Lam Ra
            19: 'كۤهۤيۤعۤصۤ', // Maryam: Kaf Ha Ya Ain Sad
            20: 'طۤهۤ', // Ta-Ha: Ta Ha
            26: 'طۤسۤمۤ', // Ash-Shu'ara: Ta Sin Mim
            27: 'طۤسۤ', // An-Naml: Ta Sin
            28: 'طۤسۤمۤ', // Al-Qasas: Ta Sin Mim
            29: 'الۤمۤ', // Al-Ankabut: Alif Lam Mim
            30: 'الۤمۤ', // Ar-Rum: Alif Lam Mim
            31: 'الۤمۤ', // Luqman: Alif Lam Mim
            32: 'الۤمۤ', // As-Sajdah: Alif Lam Mim
            36: 'يۤسۤ', // Ya-Sin: Ya Sin
            38: 'صۤ', // Sad: Sad
            40: 'حۤمۤ', // Ghafir: Ha Mim
            41: 'حۤمۤ', // Fussilat: Ha Mim
            42: 'حۤمۤ', // Ash-Shura: Ha Mim
            43: 'حۤمۤ', // Az-Zukhruf: Ha Mim
            44: 'حۤمۤ', // Ad-Dukhan: Ha Mim
            45: 'حۤمۤ', // Al-Jathiyah: Ha Mim
            46: 'حۤمۤ', // Al-Ahqaf: Ha Mim
            50: 'قۤ', // Qaf: Qaf
            68: 'نۤ', // Al-Qalam: Nun
          };
          
          // Get the pattern for this surah
          final String pattern = arabicLetterPatterns[surah.number] ?? '';
          
          if (pattern.isNotEmpty && text.contains(pattern)) {
            // Create a new text with Bismillah and pattern separated by newline
            String newText = '$matchedBismillah\n$pattern';
            
            // Update the ayah
            surah.ayahs[0] = Ayah(
              number: firstAyah.number,
              text: newText,
              numberInSurah: firstAyah.numberInSurah,
              juz: firstAyah.juz,
              page: firstAyah.page,
              sajda: firstAyah.sajda,
            );
            
            print('Processed Muqatta\'at surah ${surah.number} with pattern: $pattern');
            print('New text: $newText');
            return;
          }
        }
        
        // For all surahs (including non-Muqatta'at), we need to handle the Bismillah
        // The safest approach is to add the Bismillah as a separate line before the entire ayah text
        
        // First, check if the Bismillah is at the beginning of the text
        if (text.startsWith(matchedBismillah)) {
          // Remove the Bismillah from the beginning of the text
          String ayahText = text.substring(matchedBismillah.length).trim();
          
          // If there's no content after removing Bismillah, this means the first ayah
          // is just the Bismillah itself, which is rare but possible
          if (ayahText.isEmpty) {
            print('First ayah of Surah ${surah.number} contains only Bismillah');
            // In this case, we'll use a placeholder text to ensure we have something to display
            ayahText = "...";
          }
          
          // Create a new text with Bismillah and ayah text separated by newline
          String newText = matchedBismillah + '\n' + ayahText;
          
          // Update the ayah
          surah.ayahs[0] = Ayah(
            number: firstAyah.number,
            text: newText,
            numberInSurah: firstAyah.numberInSurah,
            juz: firstAyah.juz,
            page: firstAyah.page,
            sajda: firstAyah.sajda,
          );
          
          print('Processed Surah ${surah.number} by removing Bismillah from beginning');
          print('New text: $newText');
          return;
        } else {
          // If Bismillah is not at the beginning, it might be embedded in the text
          // We'll add it as a separate line at the beginning
          
          // Create a new text with Bismillah and the original text separated by newline
          String newText = matchedBismillah + '\n' + text;
          
          // Update the ayah
          surah.ayahs[0] = Ayah(
            number: firstAyah.number,
            text: newText,
            numberInSurah: firstAyah.numberInSurah,
            juz: firstAyah.juz,
            page: firstAyah.page,
            sajda: firstAyah.sajda,
          );
          
          print('Processed Surah ${surah.number} by adding Bismillah at beginning');
          print('New text: $newText');
          return;
        }
      } else {
        // If we couldn't find any Bismillah variation, we need to add it
        // Choose the most common Bismillah variation
        String bismillah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ';
        
        // Create a new text with Bismillah and the original text separated by newline
        String newText = bismillah + '\n' + text;
        
        // Update the ayah
        surah.ayahs[0] = Ayah(
          number: firstAyah.number,
          text: newText,
          numberInSurah: firstAyah.numberInSurah,
          juz: firstAyah.juz,
          page: firstAyah.page,
          sajda: firstAyah.sajda,
        );
        
        print('Added Bismillah to Surah ${surah.number} as it was not found');
        print('New text: $newText');
        return;
      }
    } else {
      print('Skipping non-Arabic edition for Surah ${surah.number}');
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