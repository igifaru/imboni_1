import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'shared/theme/app_theme.dart';
import 'shared/localization/app_localizations.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/admin_units_service.dart';
import 'shared/services/settings_service.dart';
import 'package:imboni/shared/auth/auth_screens.dart';
import 'package:imboni/admin/dashboard/admin_dashboard_screen.dart';
import 'package:imboni/citizen/home/citizen_home_screen.dart';
import 'package:imboni/leader/dashboard/leader_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    authService.initialize(),
    adminUnitsService.load(),
    settingsService.initialize(),
  ]);
  runApp(const ImboniApp());
}

/// Imboni App - Rwanda National Civic Governance Platform
class ImboniApp extends StatefulWidget {
  const ImboniApp({super.key});

  @override
  State<ImboniApp> createState() => _ImboniAppState();
}

class _ImboniAppState extends State<ImboniApp> {
  bool _isAuthenticated = false;
  bool _showRegister = false;
  bool _isLeader = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = authService.isAuthenticated;
    if (_isAuthenticated && authService.currentUser != null) {
      _isLeader = authService.currentUser!.isLeader;
      _isAdmin = authService.currentUser!.isAdmin;
    }
    settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
      _isLeader = authService.currentUser?.isLeader ?? false;
      _isAdmin = authService.currentUser?.isAdmin ?? false;
    });
  }

  void _onLogout() {
    authService.logout();
    setState(() {
      _isAuthenticated = false;
      _isLeader = false;
      _isAdmin = false;
    });
  }

  // Debug toggle
  void toggleUserMode() {
    setState(() {
       // simple cycle: Citizen -> Leader -> Admin -> Citizen
       if (!_isLeader && !_isAdmin) {
         _isLeader = true; 
         _isAdmin = false;
       } else if (_isLeader && !_isAdmin) {
         _isLeader = false;
         _isAdmin = true;
       } else {
         _isLeader = false;
         _isAdmin = false;
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        // Fallback delegates for Kinyarwanda (uses English defaults for system widgets)
        _RwMaterialLocalizationsDelegate(),
        _RwCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('rw')],
      localeResolutionCallback: (locale, supportedLocales) {
        final code = locale?.languageCode ?? 'rw';
        
        // Check if the current locale is supported
        for (var l in supportedLocales) {
          if (l.languageCode == code) return l;
        }
        
        // If 'rw' (default) return it, otherwise fallback to english
        if (code == 'rw') return const Locale('rw');
        
        return const Locale('en');
      },
      home: _buildHome(),
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

/// Delegate that provides English Material Localizations for Kinyarwanda
class _RwMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _RwMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';

  @override
  Future<MaterialLocalizations> load(Locale locale) async => const DefaultMaterialLocalizations();

  @override
  bool shouldReload(_RwMaterialLocalizationsDelegate old) => false;
}

/// Delegate that provides English Cupertino Localizations for Kinyarwanda
class _RwCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _RwCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async => const DefaultCupertinoLocalizations();

  @override
  bool shouldReload(_RwCupertinoLocalizationsDelegate old) => false;
}
