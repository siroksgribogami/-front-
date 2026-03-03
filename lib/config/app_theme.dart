import 'package:flutter/material.dart';

/// Тема приложения АРТхаус - уютный дом и комфорт
/// Цветовая схема 60-30-10 (Кремовый + терракот):
/// - 60% (#F7F3EC) - Кремовый фон, тёплый и домашний
/// - 30% (#6C8671) - Шалфейно-зеленый, природа и уют
/// - 10% (#D4956A) - Терракотовый акцент, земляное тепло
class AppTheme {
  // === ОСНОВНАЯ ЦВЕТОВАЯ СХЕМА 60-30-10 ===
  
  // 30% - Шалфейно-зеленый (Primary)
  static const Color primaryColor = Color(0xFF6C8671);
  static const Color primaryDark = Color(0xFF5A7360);
  static const Color primaryLight = Color(0xFF8AAA8E);
  static const Color primaryPale = Color(0xFFC4D4C8);
  
  // 60% - Кремовый фон (Background)
  static const Color backgroundColor = Color(0xFFF7F3EC);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // 10% - Терракотовый акцент (Accent/CTA)
  static const Color accentColor = Color(0xFFD4956A);
  static const Color accentDark = Color(0xFFB87848);
  static const Color accentLight = Color(0xFFE4B594);
  
  // Вспомогательные цвета
  static const Color secondaryColor = Color(0xFFEDE8E0);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF6C8671);
  static const Color warningColor = Color(0xFFE8B931);
  static const Color streakColor = Color(0xFFFF6B35); // Для streak как в Duolingo
  
  // Нейтральные оттенки
  static const Color warmGrey = Color(0xFF9AB09E);
  static const Color lightGrey = Color(0xFFEDE8E0);
  static const Color borderColor = Color(0xFFE8E2D8);
  
  // Цвета текста
  static const Color textPrimary = Color(0xFF2A3A2C);
  static const Color textSecondary = Color(0xFF5A7860);
  static const Color textHint = Color(0xFF8AAA8E);
  static const Color textOnPrimary = Colors.white;
  
  /// Светлая тема АРТхаус
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      textTheme: ThemeData().textTheme.copyWith(
            displayLarge: const TextStyle(
              fontFamily: 'Gropled',
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              color: textPrimary,
            ),
            displayMedium: const TextStyle(
              fontFamily: 'Gropled',
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: textPrimary,
            ),
            displaySmall: const TextStyle(
              fontFamily: 'Gropled',
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              color: textPrimary,
            ),
            headlineLarge: const TextStyle(
              fontFamily: 'Gropled',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: textPrimary,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'Gropled',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: textPrimary,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Gropled',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: textPrimary,
            ),
          ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        surfaceContainerHighest: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Кнопка акцента (CTA) - терракотовый
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: warmGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return IconThemeData(color: warmGrey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return TextStyle(color: warmGrey, fontSize: 12);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: warmGrey.withOpacity(0.2),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
      ),
    );
  }
  
  /// Цвета для карточек комнат - в стиле шалфейно-зеленой темы
  static Color getRoomColor(String roomType) {
    switch (roomType.toLowerCase()) {
      case 'гостиная':
      case 'living':
        return const Color(0xFFE8F0E9); // Светло-шалфейный
      case 'спальня':
      case 'bedroom':
        return const Color(0xFFF5EDE8); // Теплый кремовый
      case 'кухня':
      case 'kitchen':
        return const Color(0xFFF0E8E0); // Персиково-бежевый
      case 'ванная':
      case 'bathroom':
        return const Color(0xFFE8F0F0); // Светло-мятный
      case 'детская':
      case 'kids':
        return const Color(0xFFF0EDF5); // Лавандовый
      case 'кабинет':
      case 'office':
        return const Color(0xFFECEFEC); // Серо-зеленый
      default:
        return backgroundColor;
    }
  }
  
  /// Chip/Tag стиль для комнат и задач
  static BoxDecoration get tagDecoration => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(8),
  );
  
  /// Карточка с тенью в стиле дизайна
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
