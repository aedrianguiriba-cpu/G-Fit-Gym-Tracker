import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF3B82F6),
      secondary: const Color(0xFF60A5FA),
      surface: const Color(0xFF1A1A1A),
      background: const Color(0xFF0A0A0A),
      error: const Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    useMaterial3: true,
    brightness: Brightness.dark,
    cardTheme: CardTheme(
      elevation: 0,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: false,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF3B82F6),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: Color(0xFF3B82F6),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    ),
  );

  ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF3B82F6),
      secondary: const Color(0xFF60A5FA),
      surface: Colors.white,
      background: const Color(0xFFF8F9FA),
      error: const Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.black),
      displayMedium: TextStyle(color: Colors.black),
      displaySmall: TextStyle(color: Colors.black),
      headlineLarge: TextStyle(color: Colors.black),
      headlineMedium: TextStyle(color: Colors.black),
      headlineSmall: TextStyle(color: Colors.black),
      titleLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black),
      titleSmall: TextStyle(color: Colors.black),
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: Colors.black),
      labelLarge: TextStyle(color: Colors.black),
      labelMedium: TextStyle(color: Colors.black),
      labelSmall: TextStyle(color: Colors.black),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8F9FA),
      elevation: 0,
      centerTitle: false,
      foregroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF3B82F6),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black),
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3B82F6),
      unselectedItemColor: Color(0xFF6B7280),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(color: Colors.black),
      unselectedLabelStyle: TextStyle(color: Color(0xFF6B7280)),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.1),
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.black,
      iconColor: Colors.black,
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
    ),
  );
}
