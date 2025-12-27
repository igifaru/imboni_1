import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Settings Service - Manages user preferences locally
class SettingsService extends ChangeNotifier {
  static const String _languageKey = 'settings_language';
  static const String _emailNotifKey = 'settings_email_notifications';
  static const String _smsNotifKey = 'settings_sms_notifications';
  static const String _themeKey = 'settings_dark_mode';

  String _language = 'Kinyarwanda';
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _isDarkMode = false;
  bool _isInitialized = false;

  // Getters
  String get language => _language;
  bool get emailNotifications => _emailNotifications;
  bool get smsNotifications => _smsNotifications;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  /// Get Locale from language name
  Locale get locale {
    switch (_language) {
      case 'English': return const Locale('en');
      case 'Français': return const Locale('fr');
      default: return const Locale('rw'); // Kinyarwanda default
    }
  }

  /// Initialize settings from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _language = prefs.getString(_languageKey) ?? 'Kinyarwanda';
      _emailNotifications = prefs.getBool(_emailNotifKey) ?? true;
      _smsNotifications = prefs.getBool(_smsNotifKey) ?? false;
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Settings initialization failed: $e');
    }
  }

  /// Set language preference
  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
    notifyListeners();
  }

  /// Set email notifications preference
  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotifKey, value);
    notifyListeners();
  }

  /// Set SMS notifications preference
  Future<void> setSmsNotifications(bool value) async {
    _smsNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsNotifKey, value);
    notifyListeners();
  }

  /// Set dark mode preference
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
    notifyListeners();
  }
}

/// Global settings service instance
final settingsService = SettingsService();
