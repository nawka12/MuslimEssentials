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
    // Check if this is the first ayah (except for Surah 1 Al-Fatihah and Surah 9 At-Tawbah)
    if (ayah.numberInSurah == 1 && surahNumber != 1 && surahNumber != 9) {
      final String text = ayah.text;
      
      // Look for newline as our separator (added by the API service)
      if (text.contains('\n')) {
        final List<String> parts = text.split('\n');
        // Make sure we have at least two parts
        if (parts.length >= 2) {
          final String bismillah = parts[0].trim();
          // Join remaining parts in case there are multiple newlines
          final String ayahText = parts.sublist(1).join('\n').trim();
          
          // Return the separated parts if both are non-empty
          if (bismillah.isNotEmpty && ayahText.isNotEmpty) {
            return [bismillah, ayahText];
          }
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
    List<String> processedText;
    
    if (widget.surahNumber == 2 && widget.ayah.numberInSurah == 1) {
      // Special case for Al-Baqarah
      processedText = ['بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ', 'الۤمۤ'];
    } else {
      // Normal processing for other surahs
      processedText = _processAyahText(widget.ayah, widget.surahNumber);
    }
    
    // If hideBismillah is true, we only want the actual ayah text, not the Bismillah
    String displayText;
    if (widget.hideBismillah && processedText.length > 1) {
      // Use only the second part (the actual ayah text without Bismillah)
      displayText = processedText[1];
    } else {
      // If not separated or we want to show Bismillah, use the original text
      displayText = processedText.length > 1 ? processedText[1] : processedText[0];
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