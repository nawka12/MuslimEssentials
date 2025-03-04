import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../widgets/surah_list_item.dart';
import '../widgets/ayah_item.dart';
import '../widgets/edition_selector.dart';
import '../models/quran.dart';
import '../localizations/app_localizations.dart';
import 'dart:math' as math;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';

class QuranScreen extends StatefulWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  State<QuranScreen> createState() => _QuranScreenState();
  
  // Add a static method to reset scrolling state from anywhere
  static void resetScrollingStateForContext(BuildContext context) {
    final state = context.findAncestorStateOfType<_QuranScreenState>();
    if (state != null) {
      state.resetScrollingState();
    }
  }
}

class _QuranScreenState extends State<QuranScreen> {
  bool _isInitialized = false;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  // Track if we need to scroll to a specific ayah
  bool _needToScrollToLastRead = false;
  int? _lastReadAyahNumber;
  // Flag to show the last read indicator
  bool _showLastReadIndicator = true; // Default to true so it shows when opening a surah
  
  // Track when scrolling is complete to avoid multiple attempts
  bool _isScrollingInProgress = false;
  
  // Add a flag to track if we've already scrolled in this session
  bool _hasScrolledToLastReadInThisSession = false;
  
  Timer? _autoSaveDebounceTimer;
  
  @override
  void initState() {
    super.initState();
    // Add position listener to track visible items
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChange);
  }

  // New method to respond to position changes
  void _onItemPositionsChange() {
    // Skip tracking if we're in the middle of programmatic scrolling
    if (_isScrollingInProgress) return;
    
    if (_itemPositionsListener.itemPositions.value.isEmpty) return;
    
    // Get the currently visible items
    final visibleItems = _itemPositionsListener.itemPositions.value;
    
    // Find the item that is most centered in the viewport
    double bestVisiblePercentage = 0.0;
    int? centerItemIndex;
    
    for (final itemPosition in visibleItems) {
      // Calculate how visible this item is (0.0 to 1.0)
      double visiblePercentage = 1.0;
      if (itemPosition.itemLeadingEdge < 0) {
        visiblePercentage += itemPosition.itemLeadingEdge;
      }
      if (itemPosition.itemTrailingEdge > 1) {
        visiblePercentage -= (itemPosition.itemTrailingEdge - 1);
      }
      visiblePercentage = visiblePercentage.clamp(0.0, 1.0);
      
      // Check if this is centered better than previous best
      if (visiblePercentage > bestVisiblePercentage) {
        bestVisiblePercentage = visiblePercentage;
        centerItemIndex = itemPosition.index;
      }
    }
    
    // Auto-track the centered item if it's an ayah (not header or bismillah)
    if (centerItemIndex != null) {
      // Only continue if we have a valid surah selected
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      if (quranProvider.selectedSurah == null) return;
      
      final surah = quranProvider.selectedSurah!;
      
      // Adjust for header and bismillah to get the ayah index
      int ayahIndex = centerItemIndex;
      
      // Subtract 1 for the surah header
      ayahIndex -= 1;
      
      // Subtract 1 more for Bismillah if this surah has it
      if (surah.number != 1 && surah.number != 9) {
        ayahIndex -= 1;
      }
      
      // Only proceed if this is a valid ayah index (not header or bismillah)
      if (ayahIndex >= 0 && ayahIndex < surah.ayahs.length) {
        // Get the ayah number (1-based)
        final ayahNumber = surah.ayahs[ayahIndex].numberInSurah;
        
        // Track the position internally without visual indication
        quranProvider.trackCurrentPosition(surah.number, ayahNumber);
        
        // Auto-save the position every few seconds as the user reads
        // This uses a debounce pattern to avoid excessive saves
        if (_autoSaveDebounceTimer != null) {
          _autoSaveDebounceTimer!.cancel();
        }
        _autoSaveDebounceTimer = Timer(const Duration(seconds: 3), () {
          // Only save if we're still on the same page and not manually scrolling
          if (mounted && !_isScrollingInProgress) {
            quranProvider.saveLastReadPosition(surah.number, ayahNumber, showIndicator: false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up listeners and timers
    if (_autoSaveDebounceTimer != null) {
      _autoSaveDebounceTimer!.cancel();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Initialize the QuranProvider
      _initializeQuranProvider();
      _isInitialized = true;
    }
  }
  
  Future<void> _initializeQuranProvider() async {
    try {
      final quranProvider = Provider.of<QuranProvider>(context, listen: false);
      await quranProvider.initialize(context);
    } catch (e) {
      print('Error initializing QuranProvider: $e');
      // We'll handle errors through the provider's error state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, quranProvider, child) {
        // If a surah is selected, show the surah details screen
        if (quranProvider.selectedSurah != null) {
          // Only trigger scrolling if we haven't done it yet in this session
          if (quranProvider.lastReadSurahNumber == quranProvider.selectedSurah!.number &&
              quranProvider.lastReadAyahNumber != null && 
              !_isScrollingInProgress &&
              !_hasScrolledToLastReadInThisSession) {
            
            print("Setting up scroll to last read position: Ayah ${quranProvider.lastReadAyahNumber}");
            // Set the flag to scroll to the last read ayah
            _needToScrollToLastRead = true;
            _lastReadAyahNumber = quranProvider.lastReadAyahNumber;
            _isScrollingInProgress = true;
            _hasScrolledToLastReadInThisSession = true; // Mark that we've started scrolling
            
            // Add a safety timeout in case something goes wrong
            Timer(const Duration(seconds: 5), () {
              if (mounted && _isScrollingInProgress) {
                setState(() {
                  print("Global safety timeout: Forcing scroll unlock");
                  _isScrollingInProgress = false;
                });
              }
            });
          }
          
          return _buildSurahDetailScreen(quranProvider);
        } else {
          // Reset flags when returning to surah list
          _showLastReadIndicator = true;
          _needToScrollToLastRead = false;
          _isScrollingInProgress = false;
          _hasScrolledToLastReadInThisSession = false; // Reset the flag when returning to surah list
        }
        
        // Otherwise show the surah list screen
        return _buildSurahListScreen(quranProvider);
      },
    );
  }

  Widget _buildSurahListScreen(QuranProvider quranProvider) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'nav_quran')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              quranProvider.initialize();
            },
            tooltip: t(context, 'refresh'),
          ),
        ],
      ),
      body: quranProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : quranProvider.error != null
          ? _buildErrorWidget(quranProvider.error!)
          : _buildSurahList(quranProvider),
    );
  }

  Widget _buildSurahList(QuranProvider quranProvider) {
    final surahs = quranProvider.surahs;
    
    if (surahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              t(context, 'no_surahs_found'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                quranProvider.initialize();
              },
              child: Text(t(context, 'refresh')),
            ),
          ],
        ),
      );
    }
    
    // Use CustomScrollView to make the last read card sticky
    return CustomScrollView(
      slivers: [
        // Last read card (if exists) as a sticky header
        if (quranProvider.hasLastReadPosition)
          SliverPersistentHeader(
            pinned: true,
            delegate: _LastReadHeaderDelegate(
              child: _buildLastReadCard(quranProvider),
              maxHeight: 110,
              minHeight: 98,
            ),
          ),
        
        // Surahs list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final surah = surahs[index];
              return SurahListItem(
                surah: surah,
                onTap: () => quranProvider.loadSurah(surah.number),
              );
            },
            childCount: surahs.length,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLastReadCard(QuranProvider quranProvider) {
    // Get the surah info based on the last read surah number
    final lastReadSurah = quranProvider.surahs.firstWhere(
      (surah) => surah.number == quranProvider.lastReadSurahNumber,
      orElse: () => Surah(
        number: 1, 
        name: 'الفاتحة', 
        englishName: 'Al-Fatihah', 
        englishNameTranslation: 'The Opening', 
        numberOfAyahs: 7, 
        revelationType: 'Meccan'
      ),
    );
    
    return GestureDetector(
      onTap: () async {
        // Set flag to show the last read indicator and keep it visible
        setState(() {
          _showLastReadIndicator = true;
        });
        
        await quranProvider.goToLastReadPosition();
        // The scroll to the specific ayah will be handled in _buildScrollableContent
        _needToScrollToLastRead = true;
        _lastReadAyahNumber = quranProvider.lastReadAyahNumber;
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4), // Reduced margins
        height: 98, // Increased from 96 to provide more space
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
            width: 1, // Thinner border
          ),
        ),
        child: ClipRect( // Add ClipRect to prevent any overflow
          child: Stack(
            children: [
              // Decorative background icon
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  Icons.book_outlined,
                  size: 80, // Even smaller icon
                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(8.0), // Reduced padding even more
                child: Row(
                  children: [
                    // Left side with icon and continue reading text
                    Expanded(
                      child: SizedBox(
                        height: 72, // Increased from 70 to give a bit more space
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  size: 16, // Even smaller icon
                                ),
                                const SizedBox(width: 4), // Smaller spacing
                                Flexible(  // Wrap in Flexible to handle text overflow
                                  child: Text(
                                    t(context, 'continue_reading'),
                                    style: TextStyle(
                                      fontSize: 13, // Smaller font
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // Reduced spacing
                            Text(
                              lastReadSurah.englishName,
                              style: TextStyle(
                                fontSize: 16, // Smaller font
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis, // Handle text overflow
                            ),
                            const Spacer(flex: 1),
                            Text(
                              t(context, 'verse', args: [quranProvider.lastReadAyahNumber.toString()]),
                              style: TextStyle(
                                fontSize: 11, // Smaller font
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side with tap to continue button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Smaller padding
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        t(context, 'tap_to_continue'),
                        style: TextStyle(
                          fontSize: 11, // Smaller font
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahDetailScreen(QuranProvider quranProvider) {
    final surah = quranProvider.selectedSurah!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.englishName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => quranProvider.clearSelectedSurah(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              quranProvider.loadSurah(surah.number);
            },
            tooltip: t(context, 'refresh'),
          ),
        ],
      ),
      // Add a floating action button to manually scroll to the last read position
      floatingActionButton: (quranProvider.lastReadSurahNumber == surah.number && 
                            quranProvider.lastReadAyahNumber != null &&
                            !_isScrollingInProgress) 
        ? FloatingActionButton.small(
            child: const Icon(Icons.bookmark),
            tooltip: t(context, 'scroll_to_last_read'),
            onPressed: () {
              setState(() {
                _showLastReadIndicator = true;
                _needToScrollToLastRead = true;
                _lastReadAyahNumber = quranProvider.lastReadAyahNumber;
                _isScrollingInProgress = true;
              });
              
              // Use a post-frame callback to ensure the state update is processed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _needToScrollToLastRead) {
                  _scrollToLastReadAyah(surah);
                }
              });
            },
          )
        : null,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Translation Selector with constrained height
            if (quranProvider.editions.isNotEmpty)
              ClipRect(
                child: Container(
                  height: 52, // Even smaller height
                  margin: EdgeInsets.zero, // No margin to avoid extra space
                  padding: EdgeInsets.zero, // No padding at all
                  child: EditionSelector(
                    editions: quranProvider.editions,
                    selectedEdition: quranProvider.selectedEdition,
                    onEditionChanged: quranProvider.setSelectedEdition,
                    showNoTranslationOption: true,
                  ),
                ),
              ),
            
            // Scrollable content (includes header and ayahs)
            Expanded(
              child: quranProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : quranProvider.error != null
                  ? _buildErrorWidget(quranProvider.error!)
                  : _buildScrollableContent(surah, quranProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent(SurahDetail surah, QuranProvider quranProvider) {
    // Get the language of the selected translation
    String? translationLanguage;
    if (quranProvider.editions.isNotEmpty && quranProvider.selectedEdition != 'no_translation') {
      // Find the selected edition in the available editions
      final selectedEdition = quranProvider.editions.firstWhere(
        (edition) => edition.identifier == quranProvider.selectedEdition,
        orElse: () => QuranEdition(
          identifier: '',
          language: 'en',
          name: '',
          englishName: '',
          format: 'text',
          type: 'translation',
          direction: 'ltr',
        ),
      );
      translationLanguage = selectedEdition.language;
    }
    
    // Determine text direction for translation
    final bool isTranslationRTL = translationLanguage == 'ar' || 
                                  translationLanguage == 'ur' || 
                                  translationLanguage == 'fa';
    
    // Create data for our list items
    final List<Widget> listItems = [];
    
    // First add the surah header
    listItems.add(_buildSurahHeader(surah, context));
    
    // Then add Bismillah if needed (except for Al-Fatiha and At-Tawbah)
    if (surah.number != 1 && surah.number != 9) {
      listItems.add(_buildBismillahWidget(
        translationLanguage: translationLanguage, 
        isTranslationRTL: isTranslationRTL
      ));
    }
    
    // Then add all the ayahs
    for (int i = 0; i < surah.ayahs.length; i++) {
      final ayah = surah.ayahs[i];
      // Get the translation if it's enabled
      final translationAyah = quranProvider.selectedEdition != 'no_translation'
          ? quranProvider.getTranslationAyah(ayah.numberInSurah)
          : null;
          
      // Check if this ayah is the last read position
      final isLastRead = _showLastReadIndicator && 
                        quranProvider.lastReadSurahNumber == surah.number &&
                        quranProvider.lastReadAyahNumber == ayah.numberInSurah;
                        
      // Use a ValueKey instead of the global key
      final Key itemKey = ValueKey('ayah_${surah.number}_${ayah.numberInSurah}');
        
      // Create the ayah widget
      listItems.add(
        AyahItem(
          key: itemKey,
          ayah: ayah,
          translationAyah: translationAyah,
          translationLanguage: translationLanguage,
          surahNumber: surah.number,
          // Only hide Bismillah for first ayah in surahs that should have Bismillah header
          hideBismillah: ayah.numberInSurah == 1 && surah.number != 1 && surah.number != 9,
          isLastRead: isLastRead,
        )
      );
      
      // Check if we need to scroll to this ayah, but only if we haven't scrolled yet
      if (isLastRead && !_isScrollingInProgress && _needToScrollToLastRead) {
        _lastReadAyahNumber = ayah.numberInSurah;
      }
    }
    
    // Initialize the scroll controller only after building the list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handle scrolling to last read position
      if (_needToScrollToLastRead && _lastReadAyahNumber != null && !_itemScrollController.isAttached) {
        _isScrollingInProgress = true;
        // Wait for the controller to be attached
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToLastReadAyah(surah);
        });
      } else if (_needToScrollToLastRead && _lastReadAyahNumber != null && _itemScrollController.isAttached) {
        _isScrollingInProgress = true;
        _scrollToLastReadAyah(surah);
      }
    });
    
    // Finally, return the ScrollablePositionedList
    return ScrollablePositionedList.builder(
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      // Always use BouncingScrollPhysics to ensure scrolling is possible
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
    );
  }
  
  // Add a helper method to scroll to the last read ayah
  void _scrollToLastReadAyah(SurahDetail surah) {
    if (_lastReadAyahNumber == null || !_itemScrollController.isAttached) return;
    
    // Calculate the index to scroll to
    // We need to account for header and bismillah
    int targetIndex = _lastReadAyahNumber! - 1; // Ayah numbers are 1-based, indices are 0-based
    
    // Add 1 for the surah header
    targetIndex += 1;
    
    // Add 1 more for Bismillah if this surah has it
    if (surah.number != 1 && surah.number != 9) {
      targetIndex += 1;
    }
    
    // Set a safety timeout to unlock scrolling if callbacks fail
    Timer(const Duration(seconds: 2), () {
      if (mounted && _isScrollingInProgress) {
        setState(() {
          print("Safety timeout: Resetting scrolling lock");
          _needToScrollToLastRead = false;
          _isScrollingInProgress = false;
        });
      }
    });
    
    // Scroll to the target index with nice animation
    _itemScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
      alignment: 0.25, // Position at 25% from the top of the viewport
    ).then((_) {
      // Reset flags after scrolling
      if (mounted) {
        setState(() {
          print("Scroll completed: Resetting scrolling lock");
          _needToScrollToLastRead = false;
          _isScrollingInProgress = false;
        });
      }
    }).catchError((error) {
      // Handle errors gracefully
      if (mounted) {
        setState(() {
          print("Scroll error: $error - Resetting scrolling lock");
          _needToScrollToLastRead = false;
          _isScrollingInProgress = false;
        });
      }
    });
  }
  
  // New method to build the surah header widget
  Widget _buildSurahHeader(SurahDetail surah, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Arabic Surah Name with decorative elements
          Stack(
            alignment: Alignment.center,
            children: [
              // Decorative circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              // Surah name
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surah.name,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      shadows: [
                        Shadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0),
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          Theme.of(context).colorScheme.primary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Surah information
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  surah.englishName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  surah.englishNameTranslation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoPill(
                      context, 
                      '${surah.ayahs.length} ${t(context, 'verses')}',
                      Icons.format_list_numbered,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoPill(
                      context, 
                      surah.revelationType.toUpperCase(),
                      surah.revelationType.toLowerCase() == 'meccan' 
                        ? Icons.location_city 
                        : Icons.mosque,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // New method to build the Bismillah widget
  Widget _buildBismillahWidget({required String? translationLanguage, required bool isTranslationRTL}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Arabic Bismillah
          Text(
            'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
            style: TextStyle(
              fontSize: 28,
              height: 1.8,
              fontFamily: 'System',
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          
          // Translation of Bismillah (if translation is enabled)
          if (translationLanguage != null) ...[
            const SizedBox(height: 10),
            Text(
              _getBismillahTranslation(translationLanguage),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textDirection: isTranslationRTL ? TextDirection.rtl : TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              t(context, 'error'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final quranProvider = Provider.of<QuranProvider>(context, listen: false);
                quranProvider.initialize();
              },
              child: Text(t(context, 'retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get translation of Bismillah based on language
  String _getBismillahTranslation(String? language) {
    // Default to English
    if (language == null) {
      return 'In the name of Allah, the Most Gracious, the Most Merciful';
    }
    
    // Provide translations for common languages
    switch (language.toLowerCase()) {
      case 'fr':
        return 'Au nom d\'Allah, le Tout Miséricordieux, le Très Miséricordieux';
      case 'es':
        return 'En el nombre de Allah, el Clemente, el Misericordioso';
      case 'de':
        return 'Im Namen Allahs, des Allerbarmers, des Barmherzigen';
      case 'ur':
        return 'اللہ کے نام سے جو رحمان و رحیم ہے';
      case 'id':
        return 'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang';
      case 'tr':
        return 'Rahman ve Rahim olan Allah\'ın adıyla';
      case 'ru':
        return 'Во имя Аллаха, Милостивого, Милосердного';
      case 'fa': 
        return 'به نام خداوند بخشنده مهربان';
      case 'ja':
        return '慈悲深く慈愛あまねきアッラーの御名において';
      default:
        return 'In the name of Allah, the Most Gracious, the Most Merciful';
    }
  }

  // This allows other widgets (like AyahItem) to reset our scrolling state
  void resetScrollingState() {
    if (mounted) {
      setState(() {
        print("Manual reset: Unlocking scrolling state");
        _isScrollingInProgress = false;
      });
    }
  }
}

// Custom delegate to make the last read card sticky
class _LastReadHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;
  final double minHeight;

  _LastReadHeaderDelegate({
    required this.child,
    required this.maxHeight,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Prevent any overflow issues by clipping
    return ClipRect(
      child: Container(
        height: math.max(minHeight, maxHeight - shrinkOffset),
        // Add padding at the bottom to create space between header and list
        padding: EdgeInsets.only(bottom: overlapsContent ? 8.0 : 0.0),
        decoration: BoxDecoration(
          // Add a background color to ensure no content shows through
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_LastReadHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
           maxHeight != oldDelegate.maxHeight ||
           minHeight != oldDelegate.minHeight;
  }
} 