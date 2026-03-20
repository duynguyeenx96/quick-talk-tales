import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/speech_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_strings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SpeechProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final lang = auth.language; // 'en' or 'vi'
          final locale = lang == 'vi' ? const Locale('vi') : const Locale('en');
          return AppLocaleProvider(
            lang: lang,
            child: MaterialApp(
              title: 'Quick Talk Tales',
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('vi')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const _AuthGate(),
            ),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.state == AuthState.unknown) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) return const MainScreen();
        return const LoginScreen();
      },
    );
  }
}
