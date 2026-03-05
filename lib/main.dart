import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/apartment_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация локализации дат
  await initializeDateFormatting('ru', null);
  
  runApp(const ARThouseApp());
}

class ARThouseApp extends StatelessWidget {
  const ARThouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApartmentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Показываем загрузку при инициализации
        if (auth.state == AuthState.initial || auth.state == AuthState.loading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
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
        }

        // Если авторизован - показываем главный экран
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }

        // Иначе - показываем экран авторизации
        return const AuthFlow();
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

  void _toggleForm() {
    setState(() {
      _showLogin = !_showLogin;
    });
    // Очищаем ошибки при переключении
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        onRegisterTap: _toggleForm,
        onLoginSuccess: () {
          // Авторизация обрабатывается автоматически через Consumer
        },
      );
    } else {
      return RegisterScreen(
        onLoginTap: _toggleForm,
        onRegisterSuccess: () {
          // Регистрация обрабатывается автоматически через Consumer
        },
      );
    }
  }
}
