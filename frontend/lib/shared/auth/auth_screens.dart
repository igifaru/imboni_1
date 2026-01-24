import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/location_selector.dart';
import '../services/auth_service.dart';

import '../models/models.dart';
import '../localization/app_localizations.dart';

/// Login Screen - Professional Design
class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onRegisterTap, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // phone OR email
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() { _identifierController.dispose(); _passwordController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Kwinjira...',
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and branding
                      Center(
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primaryContainer, colorScheme.primaryContainer.withAlpha(180)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withAlpha(30),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(Icons.shield_rounded, size: 48, color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Imboni',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Iboni y'ubuyobozi bwiza",
                        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Welcome text
                      Text(
                        'Murakaza neza!',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Injira muri konti yawe',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      
                      // Phone or Email field
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Telefoni cyangwa Email',
                          hintText: '07X XXX XXXX  cyangwa  email@example.com',
                          prefixIcon: Icon(Icons.account_circle_outlined, color: colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Andika nimero ya telefoni cyangwa email';
                          // Check if it's a valid email or phone
                          final isEmail = v.contains('@') && v.contains('.');
                          final isPhone = v.length >= 10 && RegExp(r'^[0-9+]+$').hasMatch(v);
                          if (!isEmail && !isPhone) return 'Andika nimero ya telefoni (10+) cyangwa email yuzuye';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Ijambo ry\'ibanga',
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Ijambo ry\'ibanga rigomba kuba nibura inyuguti 6' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text('Wibagiwe ijambo ry\'ibanga?', style: TextStyle(color: colorScheme.primary)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Login button
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded, size: 22),
                            const SizedBox(width: 10),
                            Text('Kwinjira', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: colorScheme.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('cg', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                          Expanded(child: Divider(color: colorScheme.outlineVariant)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Register link
                      OutlinedButton(
                        onPressed: widget.onRegisterTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: colorScheme.outline, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_add_outlined, size: 22),
                            const SizedBox(width: 10),
                            Text('Iyandikishe - Konti Nshya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await authService.login(_identifierController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (response.isSuccess) {
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(response.error ?? 'Kwinjira byanze')),
          ]),
          backgroundColor: ImboniColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email cyangwa Telefoni',
            hintText: 'Andika email cyangwa nimero ya telefoni',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hagarika'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ubutumwa bwo gusubiza ijambo bwoherejwe'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Ohereza'),
          ),
        ],
      ),
    );
  }
}

/// Register Screen
class RegisterScreen extends StatefulWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({super.key, required this.onLoginTap, required this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Added email controller
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _namesController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentStep = 0;
  LocationSelection _location = const LocationSelection();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namesController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Kwiyandikisha...',
      child: Scaffold(
        appBar: AppBar(
          leading: _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)) : null,
          title: Text('Kwiyandikisha (${_currentStep + 1}/2)'),
        ),
        body: Form(
          key: _formKey,
          child: _currentStep == 0 ? _buildStep1(theme) : _buildStep2(theme),
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.primary.withAlpha(50)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_outline_rounded, color: colorScheme.onPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Amakuru y\'umuntu', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Intambwe ya 1 kuri 2', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('50%', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // Full name
            _buildStyledField(
              controller: _namesController,
              label: 'Amazina yombi',
              hint: 'Izina ry\'mbere n\'Izina ry\'umuryango',
              icon: Icons.badge_outlined,
              colorScheme: colorScheme,
              theme: theme,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().split(' ').length < 2) ? 'Andika amazina yombi' : null,
            ),
            const SizedBox(height: 20),

            // Phone
            _buildStyledField(
              controller: _phoneController,
              label: 'Nimero ya telefoni',
              hint: '07X XXX XXXX',
              icon: Icons.phone_outlined,
              colorScheme: colorScheme,
              theme: theme,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nimero ya telefoni irakenewe';
                if (!RegExp(r'^07\d{8}$').hasMatch(v)) return 'Nimero ya telefoni ntabwo yuzuye (digits 10)';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email (Optional)
            _buildStyledField(
              controller: _emailController,
              label: AppLocalizations.of(context).emailOptional,
              hint: 'email@example.com',
              icon: Icons.email_outlined,
              colorScheme: colorScheme,
              theme: theme,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.isNotEmpty && (!v.contains('@') || !v.contains('.'))) {
                  return AppLocalizations.of(context).invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // National ID
            _buildStyledField(
              controller: _nationalIdController,
              label: 'Indangamuntu',
              hint: '1 XXXX X XXXXXXX X XX',
              icon: Icons.credit_card_outlined,
              colorScheme: colorScheme,
              theme: theme,
              keyboardType: TextInputType.number,
              inputFormatters: [
                 FilteringTextInputFormatter.digitsOnly,
                 LengthLimitingTextInputFormatter(16),
              ],
              validator: (v) => (v == null || v.length != 16) ? 'Indangamuntu igomba kuba imibare 16' : null,
            ),
            const SizedBox(height: 20),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Ijambo ry\'ibanga',
                hintText: 'Nibura inyuguti 6',
                prefixIcon: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Ijambo ry\'ibanga rigomba kuba nibura inyuguti 6' : null,
            ),
            const SizedBox(height: 20),

            // Confirm password
            _buildStyledField(
              controller: _confirmPasswordController,
              label: 'Emeza ijambo ry\'ibanga',
              hint: 'Subiramo ijambo ry\'ibanga',
              icon: Icons.lock_reset_rounded,
              colorScheme: colorScheme,
              theme: theme,
              obscureText: true,
              validator: (v) => (v != _passwordController.text) ? 'Amagambo y\'ibanga ntabwo ahura' : null,
            ),
            const SizedBox(height: 32),

            // Continue button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) setState(() => _currentStep = 1);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Komeza', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Login link
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Usanzwe ufite konti? ", style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              TextButton(
                onPressed: widget.onLoginTap, 
                child: Text('Injira', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required ThemeData theme,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    int? maxLength,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        counterText: '',
      ),
      validator: validator,
    );
  }

  Widget _buildStep2(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.secondary.withAlpha(50)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on_outlined, color: colorScheme.onSecondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Aho utuye', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Intambwe ya 2 kuri 2', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('100%', style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hitamo intara, akarere, umurenge, akagari, n\'umudugudu',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            LocationSelector(
              initialSelection: _location,
              onLocationChanged: (loc) => setState(() => _location = loc),
            ),
            const SizedBox(height: 24),

            // Location confirmation
            if (_location.isComplete)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withAlpha(100)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Aho utuye hwuzuye', style: theme.textTheme.titleSmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_location.fullAddress, style: theme.textTheme.bodyMedium),
                ]),
              ),
            const SizedBox(height: 28),

            // Register button
            ElevatedButton(
              onPressed: _location.isComplete ? _register : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_location.isComplete ? Icons.check_rounded : Icons.lock_outline, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _location.isComplete ? 'Kwiyandikisha' : 'Uzuza aho utuye',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _location.isComplete ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await authService.register(
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        password: _passwordController.text,
        name: _namesController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        province: _location.province,
        district: _location.district,
        sector: _location.sector,
        cell: _location.cell,
        village: _location.village,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Kwiyandikisha byagenze neza!'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        widget.onRegisterSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(response.error ?? 'Kwiyandikisha byanze')),
          ]),
          backgroundColor: ImboniColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
