import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../localizations/app_localizations.dart';
import '../providers/quran_provider.dart';
import '../screens/quran_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';

class AyahItem extends StatefulWidget {
  final Ayah ayah;
  final Ayah? translationAyah;
  final String? translationLanguage;
  final int surahNumber;
  final bool hideBismillah;
  final bool isLastRead;

  const AyahItem({
    Key? key,
    required this.ayah,
    this.translationAyah,
    this.translationLanguage,
    required this.surahNumber,
    this.hideBismillah = false,
    this.isLastRead = false,
  }) : super(key: key);

  @override
  State<AyahItem> createState() => _AyahItemState();
}

class _AyahItemState extends State<AyahItem> {
  @override
  void initState() {
    super.initState();
    
    // Only track position for explicitly marked last read items
    if (widget.isLastRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final quranProvider = Provider.of<QuranProvider>(context, listen: false);
        quranProvider.trackCurrentPosition(widget.surahNumber, widget.ayah.numberInSurah);
      });
    }
    
    // REMOVE the automatic tracking for all items
    // This was causing the discrepancy between actual last read and saved position
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return;
    //   final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    //   quranProvider.trackCurrentPosition(widget.surahNumber, widget.ayah.numberInSurah);
    // });
  }
  
  @override
  void didUpdateWidget(AyahItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Track position ONLY when this becomes the last read ayah
    if (widget.isLastRead && !oldWidget.isLastRead) {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      quranProvider.trackCurrentPosition(widget.surahNumber, widget.ayah.numberInSurah);
    }
  }

  // Helper method to determine text direction based on language code
  TextDirection getTextDirectionForLanguage(String? languageCode) {
    // Arabic, Urdu, Persian, etc. are RTL languages
    final rtlLanguages = ['ar', 'ur', 'fa', 'he', 'ps', 'sd'];
    return (languageCode != null && rtlLanguages.contains(languageCode)) 
        ? TextDirection.rtl 
        : TextDirection.ltr;
  }

  // Helper method to separate Bismillah from first ayah text
  List<String> _processAyahText(Ayah ayah, int surahNumber) {
    // Only process the first ayah of each surah (except for Surah 1 Al-Fatihah and Surah 9 At-Tawbah)
    if (ayah.numberInSurah == 1 && surahNumber != 1 && surahNumber != 9) {
      final String text = ayah.text;
      
      // Different Unicode variations of Bismillah that might appear in the text
      final List<String> bismillahVariations = [
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ', // Common variation
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',   // Variation seen in Surah 4
        'بسم الله الرحمن الرحيم',             // Simple variation without diacritics
        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',   // Another common variation
      ];
      
      // Special handling for surahs with Arabic letters (Muqatta'at)
      final List<int> muqattaatSurahs = [2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20, 26, 27, 28, 29, 30, 31, 32, 36, 38, 40, 41, 42, 43, 44, 45, 46, 50, 68];
      
      // Map of known Arabic letter patterns for each surah
      final Map<int, String> muqattaatPatterns = {
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
      
      // Look for newline as our separator (added by the API service)
      if (text.contains('\n')) {
        final List<String> parts = text.split('\n');
        // Make sure we have at least two parts
        if (parts.length >= 2) {
          final String bismillah = parts[0].trim();
          // Join remaining parts in case there are multiple newlines
          final String ayahText = parts.sublist(1).join('\n').trim();
          
          // Check if the first part is a Bismillah variation
          bool firstPartIsBismillah = false;
          for (final b in bismillahVariations) {
            if (bismillah.trim() == b.trim()) {
              firstPartIsBismillah = true;
              break;
            }
          }
          
          // Check if the second part still contains a Bismillah variation
          bool secondPartContainsBismillah = false;
          String cleanedAyahText = ayahText;
          
          for (final b in bismillahVariations) {
            if (ayahText.contains(b)) {
              secondPartContainsBismillah = true;
              // Remove the Bismillah from the second part
              cleanedAyahText = ayahText.replaceFirst(b, '').trim();
              print('Removed duplicate Bismillah from second part for Surah $surahNumber');
              break;
            }
          }
          
          // Special handling for Muqatta'at surahs
          if (muqattaatSurahs.contains(surahNumber)) {
            final String pattern = muqattaatPatterns[surahNumber] ?? '';
            
            // If we have a pattern for this surah
            if (pattern.isNotEmpty) {
              if (firstPartIsBismillah) {
                print('Found Bismillah and Arabic letters pattern for Surah $surahNumber');
                return [bismillah, pattern];
              }
            }
          }
          
          // Return the separated parts if both are non-empty
          if (bismillah.isNotEmpty && cleanedAyahText.isNotEmpty && firstPartIsBismillah) {
            print('Successfully separated Bismillah for Surah $surahNumber using newline');
            return [bismillah, cleanedAyahText];
          } else if (bismillah.isNotEmpty && ayahText.isNotEmpty) {
            print('Successfully separated Bismillah for Surah $surahNumber using newline');
            return [bismillah, secondPartContainsBismillah ? cleanedAyahText : ayahText];
          }
        }
      }
      
      // If no newline was found, check if the text contains any variation of Bismillah
      bool containsBismillah = false;
      String matchedBismillah = '';
      
      for (final bismillah in bismillahVariations) {
        if (text.contains(bismillah)) {
          containsBismillah = true;
          matchedBismillah = bismillah;
          print('Found Bismillah variation in AyahItem for Surah $surahNumber: $matchedBismillah');
          break;
        }
      }
      
      // If we found a Bismillah variation
      if (containsBismillah) {
        // Special handling for Muqatta'at surahs
        if (muqattaatSurahs.contains(surahNumber)) {
          final String pattern = muqattaatPatterns[surahNumber] ?? '';
          
          if (pattern.isNotEmpty) {
            // If the text contains both Bismillah and the pattern, return them separately
            print('Found both Bismillah and Arabic letters pattern for Surah $surahNumber');
            return [matchedBismillah, pattern];
          }
        }
        
        // Check if the Bismillah is at the beginning of the text
        if (text.startsWith(matchedBismillah)) {
          // Remove the Bismillah from the beginning of the text
          String ayahText = text.substring(matchedBismillah.length).trim();
          
          if (ayahText.isNotEmpty) {
            print('Successfully separated Bismillah from beginning for Surah $surahNumber');
            return [matchedBismillah, ayahText];
          }
        }
        
        // List of common Arabic letter patterns that might appear in the first ayah
        final List<String> arabicLetterPatternsList = [
          'الۤمۤ', // Alif Lam Mim
          'الۤمۤصۤ', // Alif Lam Mim Sad
          'الۤرۤ', // Alif Lam Ra
          'الۤمۤرۤ', // Alif Lam Mim Ra
          'كۤهۤيۤعۤصۤ', // Kaf Ha Ya Ain Sad
          'طۤهۤ', // Ta Ha
          'طۤسۤمۤ', // Ta Sin Mim
          'طۤسۤ', // Ta Sin
          'يۤسۤ', // Ya Sin
          'صۤ', // Sad
          'حۤمۤ', // Ha Mim
          'قۤ', // Qaf
          'نۤ', // Nun
        ];
        
        // Check if the text contains any of these patterns
        for (final pattern in arabicLetterPatternsList) {
          if (text.contains(pattern)) {
            print('Found Arabic letters pattern "$pattern" for Surah $surahNumber');
            return [matchedBismillah, pattern];
          }
        }
        
        // If we couldn't separate using the above methods, just return the Bismillah and the full text
        // This ensures we don't accidentally cut off parts of the ayah
        print('Could not safely separate Bismillah for Surah $surahNumber, returning full text');
        return [matchedBismillah, text];
      }
      
      // For translations, try to identify and separate Bismillah
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
      
      // Check if the text starts with any Bismillah phrase
      for (final phrase in bismillahPhrases) {
        if (text.startsWith(phrase)) {
          // Look for end markers
          final List<String> endMarkers = ['. ', '.\n', '! ', '? '];
          int endPos = -1;
          
          for (final marker in endMarkers) {
            if (text.contains(marker)) {
              endPos = text.indexOf(marker) + 1; // include the period
              break;
            }
          }
          
          // If we found an end marker
          if (endPos > 0) {
            final String bismillah = text.substring(0, endPos);
            final String ayahText = text.substring(endPos).trim();
            
            if (bismillah.isNotEmpty && ayahText.isNotEmpty) {
              print('Successfully separated Bismillah in translation for Surah $surahNumber');
              return [bismillah, ayahText];
            }
          }
          
          break;
        }
      }
    }
    
    // For all other cases, return just the original text
    return [ayah.text];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isAppRTL = locale.languageCode == 'ar';
    
    // Always use RTL for Arabic text, but for translation use the language-specific direction
    final translationDirection = getTextDirectionForLanguage(widget.translationLanguage);
    
    // Process the ayah text to potentially separate Bismillah
    List<String> processedText = _processAyahText(widget.ayah, widget.surahNumber);
    
    // Debug the processed text
    print('Original text for Surah ${widget.surahNumber}, Ayah ${widget.ayah.numberInSurah}: ${widget.ayah.text}');
    print('Processed text parts: $processedText');
    
    // Determine what text to display based on hideBismillah flag
    String displayText = widget.ayah.text; // Initialize with default value
    
    // Special handling for first ayah of surahs (except Al-Fatihah and At-Tawbah)
    if (widget.ayah.numberInSurah == 1 && widget.surahNumber != 1 && widget.surahNumber != 9) {
      // List of Bismillah variations to check against
      final List<String> bismillahVariations = [
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ', // Common variation
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',   // Variation seen in Surah 4
        'بسم الله الرحمن الرحيم',             // Simple variation without diacritics
        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',   // Another common variation
      ];
      
      if (processedText.length > 1) {
        // Check if the first part is a Bismillah variation
        bool firstPartIsBismillah = false;
        for (final bismillah in bismillahVariations) {
          if (processedText[0].trim() == bismillah.trim()) {
            firstPartIsBismillah = true;
            break;
          }
        }
        
        // Check if the second part contains a Bismillah variation
        bool secondPartContainsBismillah = false;
        for (final bismillah in bismillahVariations) {
          if (processedText[1].contains(bismillah)) {
            secondPartContainsBismillah = true;
            break;
          }
        }
        
        if (firstPartIsBismillah) {
          // If hideBismillah is true, only show the second part (ayah text without Bismillah)
          if (widget.hideBismillah) {
            // For non-Muqatta'at surahs, we need to check if the second part still contains Bismillah
            if (secondPartContainsBismillah) {
              // If the second part still contains Bismillah, we need to remove it
              String cleanedText = processedText[1];
              for (final bismillah in bismillahVariations) {
                if (cleanedText.contains(bismillah)) {
                  cleanedText = cleanedText.replaceFirst(bismillah, '').trim();
                  print('Removed Bismillah from second part for Surah ${widget.surahNumber}');
                  break;
                }
              }
              displayText = cleanedText;
            } else {
              displayText = processedText[1];
            }
            
            // Additional check to ensure the displayText doesn't still contain Bismillah
            bool stillContainsBismillah = false;
            for (final bismillah in bismillahVariations) {
              if (displayText.contains(bismillah)) {
                displayText = displayText.replaceFirst(bismillah, '').trim();
                stillContainsBismillah = true;
                print('Found and removed additional Bismillah in displayText for Surah ${widget.surahNumber}');
                break;
              }
            }
            
            print('Hiding Bismillah for Surah ${widget.surahNumber}, showing only: $displayText');
          } else {
            // If hideBismillah is false, use the original text to ensure we don't lose any content
            displayText = widget.ayah.text;
            print('Showing full text for Surah ${widget.surahNumber}: $displayText');
          }
        } else {
          // If the first part is not a Bismillah, check if the second part contains Bismillah
          if (secondPartContainsBismillah && widget.hideBismillah) {
            // Special case: if the second part contains Bismillah and we need to hide it
            // This might happen with some Muqatta'at surahs where the order got mixed up
            String cleanedText = processedText[1];
            for (final bismillah in bismillahVariations) {
              if (cleanedText.contains(bismillah)) {
                cleanedText = cleanedText.replaceFirst(bismillah, '').trim();
                break;
              }
            }
            displayText = processedText[0] + " " + cleanedText;
            print('Special case: Hiding Bismillah from second part for Surah ${widget.surahNumber}, showing only: $displayText');
          } else {
            // Otherwise use the original text
            displayText = widget.hideBismillah ? processedText.join(' ') : widget.ayah.text;
            print('Using joined text for Surah ${widget.surahNumber}: $displayText');
          }
        }
      } else {
        // If we couldn't separate the text, check if it contains Bismillah and hide it if needed
        if (widget.hideBismillah) {
          String cleanedText = processedText[0];
          bool bismillahRemoved = false;
          
          for (final bismillah in bismillahVariations) {
            if (cleanedText.contains(bismillah)) {
              cleanedText = cleanedText.replaceFirst(bismillah, '').trim();
              displayText = cleanedText;
              bismillahRemoved = true;
              print('Removed Bismillah from unseparated text for Surah ${widget.surahNumber}');
              break;
            }
          }
          
          if (!bismillahRemoved) {
            // If no Bismillah was found or removed
            displayText = processedText[0];
            print('No Bismillah found in unseparated text for Surah ${widget.surahNumber}');
          }
        } else {
          // If hideBismillah is false, use the original text
          displayText = widget.ayah.text;
          print('Using original text for Surah ${widget.surahNumber} (could not separate)');
        }
      }
      
      // Special handling for surahs with Arabic letters (Muqatta'at)
      final List<int> muqattaatSurahs = [2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 20, 26, 27, 28, 29, 30, 31, 32, 36, 38, 40, 41, 42, 43, 44, 45, 46, 50, 68];
      
      // If this is the first ayah of a Muqatta'at surah and hideBismillah is true,
      // make sure we're only showing the Arabic letters, not the Bismillah
      if (widget.hideBismillah && muqattaatSurahs.contains(widget.surahNumber)) {
        // Map of known Arabic letter patterns for each surah
        final Map<int, String> muqattaatPatterns = {
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
        final String pattern = muqattaatPatterns[widget.surahNumber] ?? '';
        
        // If we have a pattern for this surah, use it directly
        if (pattern.isNotEmpty) {
          // For Muqatta'at surahs, we should just show the Arabic letters pattern
          // regardless of what's in the displayText
          displayText = pattern;
          print('Using Arabic letter pattern for Muqatta\'at Surah ${widget.surahNumber}: $pattern');
        }
      }
    } else {
      // For all other ayahs, use the original text
      displayText = widget.ayah.text;
    }
    
    // Make sure to forward the key explicitly to the outermost Widget
    // to prevent automatic key propagation to child widgets
    return GestureDetector(
      key: null, // Explicitly set to null to ensure widget.key is not used here
      onLongPress: () {
        _showAyahMenu(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isLastRead 
              ? theme.colorScheme.tertiary.withOpacity(0.1) 
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: widget.isLastRead
              ? Border.all(color: theme.colorScheme.tertiary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayah header with number and metadata
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                textDirection: isAppRTL ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.ayah.numberInSurah.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${t(context, 'juz', args: [widget.ayah.juz.toString()])} · ${t(context, 'page', args: [widget.ayah.page.toString()])}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.secondary,
                      ),
                      textDirection: isAppRTL ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bismillah display if present and not hidden
            if (!widget.hideBismillah && processedText.length > 1) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  processedText[0],
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.8,
                    fontFamily: 'System', // Using system font for Arabic
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl, // Arabic is always RTL
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            // Arabic Text Container
            Container(
              padding: EdgeInsets.fromLTRB(20, (!widget.hideBismillah && processedText.length > 1) ? 10 : 20, 20, 16),
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.8,
                  fontFamily: 'System', // Using system font for Arabic
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textDirection: TextDirection.rtl, // Arabic is always RTL
                textAlign: TextAlign.justify,
              ),
            ),
            
            // Translation if available
            if (widget.translationAyah != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  widget.translationAyah!.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                  // Set text direction based on translation language
                  textDirection: translationDirection,
                  textAlign: translationDirection == TextDirection.rtl 
                    ? TextAlign.justify 
                    : TextAlign.left,
                ),
              ),
            ],
            
            // Last Read Indicator - only show if this is explicitly the last read position
            if (widget.isLastRead) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_added,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t(context, 'last_read_position'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Add this method to show the ayah options menu
  void _showAyahMenu(BuildContext context) {
    final theme = Theme.of(context);
    final quranProvider = Provider.of<QuranProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Menu title with ayah number
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '${t(context, 'ayah')} ${widget.ayah.numberInSurah}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                
                // Mark as last read
                ListTile(
                  leading: Icon(
                    Icons.bookmark_added,
                    color: theme.colorScheme.tertiary,
                  ),
                  title: Text(t(context, 'mark_last_read')),
                  onTap: () {
                    Navigator.pop(context);
                    
                    // Save the last read position with visual indicator
                    quranProvider.saveLastReadPosition(
                      widget.surahNumber, 
                      widget.ayah.numberInSurah,
                      showIndicator: true
                    );
                    
                    // Show a snackbar confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t(context, 'marked_as_last_read')),
                        backgroundColor: theme.colorScheme.tertiary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    
                    // Explicitly allow scrolling again by resetting the flag in QuranScreen
                    // This needs to be done after a small delay to ensure the UI has updated
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (!mounted) return;
                      QuranScreen.resetScrollingStateForContext(context);
                    });
                  },
                ),
                
                // Share ayah
                ListTile(
                  leading: Icon(
                    Icons.share,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(t(context, 'share')),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement sharing functionality
                    // This is optional and can be implemented later
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 