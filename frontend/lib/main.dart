import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'shared/theme/app_theme.dart';
import 'shared/localization/app_localizations.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/settings_service.dart';
import 'package:imboni/shared/auth/auth_screens.dart';
import 'package:imboni/admin/dashboard/admin_dashboard_screen.dart';
import 'package:imboni/citizen/home/citizen_home_screen.dart';
import 'package:imboni/leader/dashboard/leader_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:imboni/features/community/providers/community_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settingsService.initialize();
  // Ensure auth service initialized (check token)
  await authService.initialize(); 
  runApp(const ImboniApp());
}

class ImboniApp extends StatefulWidget {
  const ImboniApp({super.key});

  @override
  State<ImboniApp> createState() => _ImboniAppState();
}

class _ImboniAppState extends State<ImboniApp> {
  bool _showRegister = false;
  
  // Listen to auth service changes
  @override
  void initState() {
    super.initState();
    authService.addListener(_onAuthChange);
    settingsService.addListener(_onSettingsChange);
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthChange);
    settingsService.removeListener(_onSettingsChange);
    super.dispose();
  }

  void _onAuthChange() => setState(() {});
  void _onSettingsChange() => setState(() {});

  bool get _isAuthenticated => authService.isAuthenticated;
  bool get _isAdmin => authService.currentUser?.role == 'ADMIN';
  // Check for leader roles (VILLAGE_LEADER, etc.)
  bool get _isLeader => authService.currentUser?.role != 'CITIZEN' && authService.currentUser?.role != 'ADMIN';

  void _onLoginSuccess() {
    setState(() {
      _showRegister = false;
    });
  }

  void _onLogout() {
    authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: MaterialApp(
        title: 'Imboni',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settingsService.themeMode,
        locale: settingsService.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          // Fallback delegates for Kinyarwanda
          _RwMaterialLocalizationsDelegate(),
          _RwCupertinoLocalizationsDelegate(),
        ],
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('rw')],
        localeResolutionCallback: (locale, supportedLocales) {
          final code = locale?.languageCode ?? 'rw';
          for (var l in supportedLocales) {
            if (l.languageCode == code) return l;
          }
          if (code == 'rw') return const Locale('rw');
          return const Locale('en');
        },
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (!_isAuthenticated) {
      if (_showRegister) {
        return RegisterScreen(
          onLoginTap: () => setState(() => _showRegister = false),
          onRegisterSuccess: _onLoginSuccess,
        );
      }
      return LoginScreen(
        onRegisterTap: () => setState(() => _showRegister = true),
        onLoginSuccess: _onLoginSuccess,
      );
    }

    if (_isAdmin) {
      return AdminDashboardScreen(onLogout: _onLogout);
    }

    if (_isLeader) {
      return const LeaderDashboardScreen();
    }
    
    return const CitizenHomeScreen();
  }
}

class _RwMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _RwMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';
  @override
  Future<MaterialLocalizations> load(Locale locale) async => const DefaultMaterialLocalizations();
  @override
  bool shouldReload(_RwMaterialLocalizationsDelegate old) => false;
}

class _RwCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _RwCupertinoLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';
  @override
  Future<CupertinoLocalizations> load(Locale locale) async => const DefaultCupertinoLocalizations();
  @override
  bool shouldReload(_RwCupertinoLocalizationsDelegate old) => false;
}
