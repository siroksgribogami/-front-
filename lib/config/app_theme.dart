import 'package:flutter/material.dart';
import 'brand_colors.dart';
import 'text_theme.dart';

/// Тема Приделе — брендбук «При деле» (60-30-10: холст / хвоя / глина).
class AppTheme {
  static const Color primaryDeep = BrandColors.needlesDeep;
  static const Color primaryColor = BrandColors.needles;
  static const Color primaryDark = primaryDeep;
  static const Color primaryLight = BrandColors.needlesLight;
  static const Color primaryPale = BrandColors.linen;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primaryColor],
  );

  static BoxDecoration brandGradientDecoration({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: const [primaryDeep, primaryColor],
        ),
      );
  
  static const Color backgroundColor = BrandColors.canvas;
  static const Color surfaceColor = BrandColors.milk;
  static const Color cardColor = BrandColors.milk;

  /// Единственный clay-CTA на экране (отправка, 3D).
  static const Color accentColor = BrandColors.clay;
  static const Color accentDark = BrandColors.surik;
  static const Color accentLight = BrandColors.dawn;

  static const Color secondaryColor = BrandColors.linen;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = primaryColor;
  static const Color warningColor = Color(0xFFE8B931);
  static const Color streakColor = Color(0xFFFF6B35); // Для streak как в Duolingo
  
  // Нейтральные оттенки
  static const Color warmGrey = Color(0xFF6B7A72);
  static const Color lightGrey = BrandColors.linen;
  static const Color borderColor = BrandColors.borderSubtle;

  static const Color textPrimary = BrandColors.tar;
  static const Color textSecondary = Color(0xFF3D4A42);
  static const Color textHint = Color(0xFF5C6B62);
  static const Color textOnPrimary = Colors.white;

  /// Подписи кнопок и UI — Inter (Pochaevsk только display).
  static const TextStyle buttonLabelStyle = TextStyle(
    fontFamily: AppTextStyle.uiFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );
  
  /// Светлая тема Приделе
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      // iOS-стиль перехода между экранами (slide-from-right с тенью).
      // На Android-устройствах вроде Samsung A54 это даёт «дорогую» анимацию
      // навигации, причём дешевле по GPU, чем Material shared-axis.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
            displayLarge: pochaevsk(fontSize: 80, fontWeight: FontWeight.w400, letterSpacing: -1.5),
            displayMedium: pochaevsk(fontSize: 48, fontWeight: FontWeight.w400, letterSpacing: -1.2),
            displaySmall: pochaevsk(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: -1.0),
            headlineLarge: pochaevsk(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -0.8),
            headlineMedium: pochaevsk(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: -0.6),
            titleLarge: pochaevsk(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: -0.4),
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
        centerTitle: false,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01 * 18,
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
          textStyle: buttonLabelStyle,
        ),
      ),
      // Кнопка акцента (CTA) — глина, один на экран
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: buttonLabelStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: BrandColors.milk,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          side: const BorderSide(color: borderColor, width: 1.5),
          textStyle: buttonLabelStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: buttonLabelStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        extendedTextStyle: buttonLabelStyle.copyWith(color: Colors.white),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: warmGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: buttonLabelStyle.copyWith(fontSize: 12, letterSpacing: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: warmGrey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return buttonLabelStyle.copyWith(color: primaryColor, fontSize: 12, letterSpacing: 0);
          }
          return buttonLabelStyle.copyWith(color: warmGrey, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0);
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
        labelStyle: buttonLabelStyle.copyWith(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandColors.radiusChip),
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
        return const Color(0xFFC8DFC9); // Насыщенный шалфейный
      case 'спальня':
      case 'bedroom':
        return const Color(0xFFEFD9C8); // Персиково-розовый
      case 'кухня':
      case 'kitchen':
        return const Color(0xFFEFD8A8); // Тёплый янтарный
      case 'ванная':
      case 'bathroom':
        return const Color(0xFFB8DADA); // Насыщенный мятный
      case 'детская':
      case 'kids':
        return const Color(0xFFCFC4E6); // Лавандовый
      case 'кабинет':
      case 'office':
        return const Color(0xFFBECDBE); // Оливково-зелёный
      case 'прихожая':
        return const Color(0xFFE0CEB8); // Тёплый песочный
      case 'балкон':
      case 'лоджия':
        return const Color(0xFFB8D0D8); // Небесно-голубой
      case 'гардероб':
        return const Color(0xFFD8C4DE); // Сиреневый
      case 'столовая':
        return const Color(0xFFE6CCA6); // Карамельный
      case 'терраса':
        return const Color(0xFFB8D4BA); // Садово-зелёный
      case 'коридор':
        return const Color(0xFFD4D4D0); // Нейтральный серый
      case 'кладовая':
        return const Color(0xFFD8C9B0); // Песочный
      case 'гостевая':
        return const Color(0xFFE6CCCC); // Нежно-розовый
      case 'игровая':
        return const Color(0xFFB8C8E6); // Васильковый
      default:
        return backgroundColor;
    }
  }

  /// Цвета комнат для тёмной темы — приглушённые тёмные тона
  static Color getRoomColorDark(String roomType) {
    switch (roomType.toLowerCase()) {
      case 'гостиная':
      case 'living':
        return const Color(0xFF243028); // тёмный шалфей
      case 'спальня':
      case 'bedroom':
        return const Color(0xFF332820); // тёмный персик
      case 'кухня':
      case 'kitchen':
        return const Color(0xFF302A18); // тёмный янтарь
      case 'ванная':
      case 'bathroom':
        return const Color(0xFF1A2E2E); // тёмная мята
      case 'детская':
      case 'kids':
        return const Color(0xFF28243A); // тёмная лаванда
      case 'кабинет':
      case 'office':
        return const Color(0xFF202820); // тёмный оливковый
      case 'прихожая':
        return const Color(0xFF2E2618); // тёмный песок
      case 'балкон':
      case 'лоджия':
        return const Color(0xFF1A2A30); // тёмное небо
      case 'гардероб':
        return const Color(0xFF2A2032); // тёмная сирень
      case 'столовая':
        return const Color(0xFF2E2418); // тёмная карамель
      case 'терраса':
        return const Color(0xFF1E2C1E); // тёмный сад
      case 'коридор':
        return const Color(0xFF282828); // нейтральный тёмный
      case 'кладовая':
        return const Color(0xFF2A2418); // тёмный песчаник
      case 'гостевая':
        return const Color(0xFF2E2020); // тёмная роза
      case 'игровая':
        return const Color(0xFF1E2232); // тёмный василёк
      default:
        return darkCard;
    }
  }

  // ============================================================
  // ТЁМНАЯ ТЕМА — «Уголь + лес»
  // 60% уголь · 30% хвоя · 10% глина
  // ============================================================

  // Тёмная палитра — уголь + тёмно-зелёный акцент
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface    = Color(0xFF1E1E1E); // nav bg
  static const Color darkCard       = Color(0xFF252525);
  static const Color darkBorder     = Color(0xFF2E2E2E);
  static const Color darkAccent     = BrandColors.clay;
  static const Color darkAccentDark = Color(0xFFB8784E);
  static const Color darkTextPrimary    = Color(0xFFEAE8E4);
  static const Color darkTextSecondary  = Color(0xFFADABA6);
  static const Color darkTextHint       = Color(0xFF787674);
  static const Color darkSecondary      = Color(0xFF222222);

  /// Тёмная тема Приделе
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: pochaevsk(fontSize: 80, fontWeight: FontWeight.w400, letterSpacing: -1.5, color: darkTextPrimary),
        displayMedium: pochaevsk(fontSize: 48, fontWeight: FontWeight.w400, letterSpacing: -1.2, color: darkTextPrimary),
        displaySmall: pochaevsk(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: -1.0, color: darkTextPrimary),
        headlineLarge: pochaevsk(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -0.8, color: darkTextPrimary),
        headlineMedium: pochaevsk(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: -0.6, color: darkTextPrimary),
        titleLarge: pochaevsk(fontSize: 20, fontWeight: FontWeight.w400, letterSpacing: -0.4, color: darkTextPrimary),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: darkSecondary,
        tertiary: darkAccent,
        error: errorColor,
        surface: darkSurface,
        surfaceContainerHighest: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01 * 18,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        color: darkCard,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
          textStyle: buttonLabelStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: buttonLabelStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          side: const BorderSide(color: darkBorder, width: 1.5),
          textStyle: buttonLabelStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: buttonLabelStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextHint),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        extendedTextStyle: buttonLabelStyle.copyWith(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: buttonLabelStyle.copyWith(fontSize: 12, letterSpacing: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: primaryColor.withOpacity(0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight);
          }
          return const IconThemeData(color: darkTextHint);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return buttonLabelStyle.copyWith(color: primaryLight, fontSize: 12, letterSpacing: 0);
          }
          return buttonLabelStyle.copyWith(color: darkTextHint, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkTextPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: buttonLabelStyle.copyWith(color: darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandColors.radiusChip),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkBorder.withOpacity(0.4),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: darkTextSecondary,
      ),
    );
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
