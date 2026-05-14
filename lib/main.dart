import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_navigation.dart';
import 'state/app_state.dart';
import 'screens/auth_screen.dart';
import 'models/schema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().init();
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isAuthenticated,
      builder: (context, isAuthenticated, child) {
        return ValueListenableBuilder<User?>(
          valueListenable: AppState().user,
          builder: (context, user, child) {
            final isDarkMode = user?.themePreference == 'dark';
            
            return MaterialApp(
              title: 'Control Financiero',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(isDarkMode),
              home: isAuthenticated ? const MainNavigation() : const AuthScreen(),
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme(bool isDarkMode) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFCE4EC),
      primary: isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFF48FB1),
      secondary: isDarkMode ? const Color(0xFFE91E63) : const Color(0xFFCE93D8),
      tertiary: isDarkMode ? const Color(0xFF00BCD4) : const Color(0xFF81D4FA),
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      surface: isDarkMode ? const Color(0xFF121212) : Colors.white,
      error: isDarkMode ? const Color(0xFFFF6B6B) : Colors.red,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: isDarkMode ? const Color(0xFF0B0B0E) : const Color(0xFFFFFBF9),
      colorScheme: colorScheme,
      textTheme: GoogleFonts.outfitTextTheme(
        isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: isDarkMode ? Colors.white : Colors.black87,
        displayColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.withOpacity(0.1),
          ),
        ),
        color: isDarkMode ? const Color(0xFF1A1A1E) : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF1A1A1E) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.2),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
