import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/api_config_platform_stub.dart' if (dart.library.io) 'config/api_config_platform_io.dart' as api_platform;
import 'config/app_theme.dart';
import 'config/webview_web_register.dart';
import 'core/bar_loader.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/role_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/post_register_survey_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/mobile_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerWebViewPlatformForWeb();

  api_platform.initApiConfigForPlatform();
  if (!kIsWeb) {
    _setSystemUIOverlay();
  }

  await initializeDateFormatting('ru', null);

  runApp(const ArtkhausApp());
}

void _setSystemUIOverlay() {
  _applySystemUIOverlay(Brightness.light);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

void _applySystemUIOverlay(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F3EC),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
}

class ArtkhausApp extends StatelessWidget {
  const ArtkhausApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          final platformBrightness = MediaQuery.platformBrightnessOf(context);
          final effectiveBrightness = switch (themeProv.themeMode) {
            ThemeMode.light => Brightness.light,
            ThemeMode.dark => Brightness.dark,
            ThemeMode.system => platformBrightness,
          };
          _applySystemUIOverlay(effectiveBrightness);

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeProv.fontScale),
            ),
            child: MaterialApp(
              title: 'АРТхаус',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProv.themeMode,
              // Глобальный фоллбэк на OpenMoji для всех эмодзи в приложении
              builder: (context, child) {
                return DefaultTextStyle(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    // Primary fallback for emoji: Noto Color Emoji (add TTF to fonts/)
                    fontFamilyFallback: const ['NotoColorEmoji', 'OpenMoji'],
                  ),
                  child: child!,
                );
              },
              home: const AppRoot(),
            ),
          );
        },
      ),
    );
  }
}

/// Корневой виджет для управления перехода между экранами
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    // Инициализация при старте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
      context.read<RoleProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        Widget screen;
        String screenKey;

        // Показываем загрузку только до завершения первичной инициализации,
        // чтобы ошибки входа не сбрасывали пользователя в стартовый auth-экран.
        if (!auth.isInitialized) {
          screenKey = 'loading';
          screen = const Scaffold(
            key: ValueKey('loading'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.architecture_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 24),
                  BarLoader(
                    color: AppTheme.primaryColor,
                    inactiveOpacity: 0.45,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Загрузка...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (auth.needsEmailVerification) {
          screenKey = 'verify_email';
          screen = EmailVerificationScreen(
            key: const ValueKey('verify_email'),
            onContinue: () {
              context.read<AuthProvider>().completeEmailVerificationStep();
            },
          );
        } else if (auth.justRegistered) {
          // Короткий экран-приветствие после регистрации.
          screenKey = 'welcome';
          screen = WelcomeScreen(
            key: const ValueKey('welcome'),
            onContinue: () {
              context.read<AuthProvider>().completePostRegisterWelcome();
            },
          );
        } else if (auth.needsSurvey) {
          // Если авторизован, но не прошел опрос - показываем опрос
          screenKey = 'survey';
          screen = const PostRegisterSurveyScreen(key: ValueKey('survey'));
        } else if (auth.isAuthenticated) {
          // Если авторизован - показываем главный экран
          screenKey = 'home';
          // Web → sidebar, Android/мобиль → нижняя навигация
          screen = kIsWeb
              ? const HomeScreen(key: ValueKey('home'))
              : const MobileHomeScreen(key: ValueKey('home'));
        } else {
          // Иначе - показываем экран авторизации
          screenKey = 'auth';
          screen = const AuthFlow(key: ValueKey('auth'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          layoutBuilder: (currentChild, previousChildren) {
            final bg = Theme.of(context).scaffoldBackgroundColor;
            return ColoredBox(
              color: bg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(key: ValueKey(screenKey), child: screen),
        );
      },
    );
  }
}

/// Флоу авторизации (Login/Register)
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _showLogin = true;

  void _goToRegister() {
    context.read<AuthProvider>().clearError();
    setState(() => _showLogin = false);
  }

  void _goToLogin() {
    context.read<AuthProvider>().clearError();
    setState(() => _showLogin = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (currentChild, previousChildren) {
        // Тот же зелёный, что у Login/Register — иначе при cross-fade на секунду виден фон темы (тёмный в dark mode).
        return ColoredBox(
          color: AppTheme.primaryColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showLogin
          ? LoginScreen(
              key: const ValueKey('login'),
              onRegisterTap: _goToRegister,
              onLoginSuccess: () {/* handled by AppRoot Consumer */},
            )
          : RegisterScreen(
              key: const ValueKey('register'),
              onLoginTap: _goToLogin,
              onRegisterSuccess: () {/* handled by AppRoot Consumer */},
            ),
    );
  }
}
