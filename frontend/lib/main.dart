import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'shared/theme/app_theme.dart';
import 'shared/localization/app_localizations.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/admin_units_service.dart';
import 'shared/auth/auth_screens.dart';
import 'citizen/home/citizen_home_screen.dart';
import 'leader/dashboard/leader_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    authService.initialize(),
    adminUnitsService.load(),
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
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAuthenticated = false;
  bool _showRegister = false;
  bool _isLeader = false;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = authService.isAuthenticated;
    if (_isAuthenticated && authService.currentUser != null) {
      _isLeader = authService.currentUser!.isLeader;
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
      _isLeader = authService.currentUser?.isLeader ?? false;
    });
  }

  void _onLogout() {
    authService.logout();
    setState(() {
      _isAuthenticated = false;
      _isLeader = false;
    });
  }

  void toggleUserMode() => setState(() => _isLeader = !_isLeader);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imboni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
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

    return Scaffold(
      body: _isLeader ? const LeaderDashboardScreen() : const CitizenHomeScreen(),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'mode_toggle',
        onPressed: toggleUserMode,
        tooltip: _isLeader ? 'Switch to Citizen' : 'Switch to Leader',
        child: Icon(_isLeader ? Icons.person : Icons.admin_panel_settings),
      ),
    );
  }
}
