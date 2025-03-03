import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../services/quran_api_service.dart';
import '../services/database_helper.dart';
import 'package:flutter/widgets.dart';

class QuranProvider extends ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<Surah> _surahs = [];
  List<Surah> get surahs => _surahs;
  
  SurahDetail? _selectedSurah;
  SurahDetail? get selectedSurah => _selectedSurah;
  
  SurahDetail? _translationSurah;
  SurahDetail? get translationSurah => _translationSurah;
  
  List<QuranEdition> _editions = [];
  List<QuranEdition> get editions => _editions;
  
  String _selectedEdition = 'en.asad'; // Default to English translation
  String get selectedEdition => _selectedEdition;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  Locale? _appLocale;
  
  // Last read position (this is shown to the user)
  int? _lastReadSurahNumber;
  int? _lastReadAyahNumber;
  bool get hasLastReadPosition => _lastReadSurahNumber != null && _lastReadAyahNumber != null;
  int? get lastReadSurahNumber => _lastReadSurahNumber;
  int? get lastReadAyahNumber => _lastReadAyahNumber;
  
  // Current tracking position (not visible to user, just tracking in background)
  int? _currentSurahNumber;
  int? _currentAyahNumber;
  DateTime _lastPositionUpdate = DateTime.now();
  
  // How often to save the current position (to avoid excessive database writes)
  static const Duration _positionUpdateThreshold = Duration(seconds: 10);
  
  // Initialize by fetching the surahs and available editions
  Future<void> initialize([BuildContext? context]) async {
    setLoading(true);
    _error = null;
    try {
      // Set app locale if context is provided
      if (context != null) {
        _appLocale = Localizations.localeOf(context);
      }
      
      // Load surahs
      _surahs = await _apiService.getSurahs();
      
      // Load available editions based on the device locale
      String languageCode = _appLocale?.languageCode ?? 'en';
      await loadEditions(languageCode);
      
      // Set default translation edition
      _setDefaultEdition();
      
      // Load last read position
      await loadLastReadPosition();
      
      setLoading(false);
    } catch (e) {
      _error = e.toString();
      setLoading(false);
    }
  }
  
  // Set a default edition from available editions
  void _setDefaultEdition() {
    // Get language from app locale or use 'en' as default
    String languageCode = _appLocale?.languageCode ?? 'en';
    
    // Try to find translations in the device's language
    var localeEditions = _editions.where((edition) => 
      edition.language == languageCode && edition.format == 'text');
    
    if (localeEditions.isNotEmpty) {
      _selectedEdition = localeEditions.first.identifier;
      return;
    }
    
    // Try to find Asad's translation if no locale editions (popular English translation)
    bool hasAsad = _editions.any((edition) => edition.identifier == 'en.asad');
    if (hasAsad) {
      _selectedEdition = 'en.asad';
      return;
    }
    
    // Then try any English translation
    var englishEditions = _editions.where((edition) => 
      edition.language == 'en' && edition.format == 'text');
    if (englishEditions.isNotEmpty) {
      _selectedEdition = englishEditions.first.identifier;
      return;
    }
    
    // Finally, just use the first available edition
    if (_editions.isNotEmpty) {
      _selectedEdition = _editions.first.identifier;
    }
  }
  
  // Load editions by language
  Future<void> loadEditions(String language) async {
    setLoading(true);
    try {
      _editions = await _apiService.getEditions(language);
      
      // If no editions found for this language, try getting all editions
      if (_editions.isEmpty && language.isNotEmpty) {
        _editions = await _apiService.getEditions('');
      }
      
      // Filter to only include text translations (not audio and not Arabic)
      _editions = _editions.where((edition) => 
        edition.format == 'text' && 
        edition.type == 'translation' &&
        edition.language != 'ar').toList();
      
      setLoading(false);
    } catch (e) {
      _error = e.toString();
      setLoading(false);
    }
  }
  
  // Change the selected edition
  void setSelectedEdition(String editionId) {
    _selectedEdition = editionId;
    if (_selectedSurah != null) {
      // If we have a surah loaded, reload it with the new translation
      loadSurah(_selectedSurah!.number);
    }
    notifyListeners();
  }
  
  // Load a specific surah
  Future<void> loadSurah(int surahNumber) async {
    setLoading(true);
    _error = null;
    try {
      // First, load the Arabic text (quran-uthmani)
      _selectedSurah = await _apiService.getSurah(surahNumber, 'quran-uthmani');
      
      // Then load the translation
      _translationSurah = await _apiService.getSurah(surahNumber, _selectedEdition);
      
      setLoading(false);
    } catch (e) {
      _error = e.toString();
      setLoading(false);
    }
  }
  
  // Get translation ayah that matches the Arabic ayah
  Ayah? getTranslationAyah(int numberInSurah) {
    if (_translationSurah == null) return null;
    
    try {
      return _translationSurah!.ayahs.firstWhere(
        (ayah) => ayah.numberInSurah == numberInSurah
      );
    } catch (e) {
      return null;
    }
  }
  
  // Helper to set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Clear the selected surah (return to surah list)
  void clearSelectedSurah() {
    // Before clearing, make sure we've persisted the latest position
    _persistCurrentPosition(forceUpdate: true);
    
    // Also sync our UI markers with the current tracked position
    if (_currentSurahNumber != null && _currentAyahNumber != null) {
      _lastReadSurahNumber = _currentSurahNumber;
      _lastReadAyahNumber = _currentAyahNumber;
    }
    
    _selectedSurah = null;
    _translationSurah = null;
    notifyListeners();
  }

  // Position Tracking Methods
  
  // Track the current position without updating the UI marker
  void trackCurrentPosition(int surahNumber, int ayahNumber) {
    _currentSurahNumber = surahNumber;
    _currentAyahNumber = ayahNumber;
    
    // Check if we should update the database
    final now = DateTime.now();
    if (now.difference(_lastPositionUpdate) > _positionUpdateThreshold) {
      _lastPositionUpdate = now;
      // Save to database without updating the UI marker
      _persistCurrentPosition();
    }
  }
  
  // Persist the current position to database without updating the UI
  Future<void> _persistCurrentPosition({bool forceUpdate = false}) async {
    if (_currentSurahNumber != null && _currentAyahNumber != null) {
      try {
        final now = DateTime.now();
        
        // Only update if forced or if enough time has passed since last update
        if (forceUpdate || now.difference(_lastPositionUpdate) > _positionUpdateThreshold) {
          await _databaseHelper.saveLastReadPosition(_currentSurahNumber!, _currentAyahNumber!);
          _lastPositionUpdate = now;
        }
      } catch (e) {
        print('Error saving current position: $e');
      }
    }
  }
  
  // Load the last read position from the database
  Future<void> loadLastReadPosition() async {
    try {
      final lastPosition = await _databaseHelper.getLastReadPosition();
      if (lastPosition != null) {
        _lastReadSurahNumber = lastPosition['surah_number'];
        _lastReadAyahNumber = lastPosition['ayah_number'];
        // Also initialize the current position to match
        _currentSurahNumber = _lastReadSurahNumber;
        _currentAyahNumber = _lastReadAyahNumber;
      } else {
        _lastReadSurahNumber = null;
        _lastReadAyahNumber = null;
        _currentSurahNumber = null;
        _currentAyahNumber = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading last read position: $e');
    }
  }
  
  // Explicitly save and show the last read position (used for "mark as last read")
  Future<void> saveLastReadPosition(int surahNumber, int ayahNumber, {bool showIndicator = true}) async {
    try {
      await _databaseHelper.saveLastReadPosition(surahNumber, ayahNumber);
      _currentSurahNumber = surahNumber;
      _currentAyahNumber = ayahNumber;
      _lastPositionUpdate = DateTime.now();
      
      // Only update the visible UI indicator if showIndicator is true
      if (showIndicator) {
        _lastReadSurahNumber = surahNumber;
        _lastReadAyahNumber = ayahNumber;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving last read position: $e');
    }
  }
  
  // Navigate to the last read position
  Future<void> goToLastReadPosition() async {
    if (lastReadSurahNumber != null) {
      // Load the surah where the last read position is located
      await loadSurah(lastReadSurahNumber!);
      
      // Synchronize current position with last read position
      _currentSurahNumber = _lastReadSurahNumber;
      _currentAyahNumber = _lastReadAyahNumber;
      
      // The actual scrolling to the specific ayah will be handled by the QuranScreen
      notifyListeners();
    }
  }
  
  // Update UI to show the current position as the last read position
  // Call this only when explicitly wanting to update the UI marker
  Future<void> updateLastReadMarker() async {
    if (_currentSurahNumber != null && _currentAyahNumber != null) {
      _lastReadSurahNumber = _currentSurahNumber;
      _lastReadAyahNumber = _currentAyahNumber;
      notifyListeners();
    }
  }
} 