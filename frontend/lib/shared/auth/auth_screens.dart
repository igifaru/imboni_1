import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/location_selector.dart';
import '../services/auth_service.dart';
import '../services/admin_units_service.dart';

/// Login Screen
class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onRegisterTap, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() { _phoneController.dispose(); _passwordController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Kwinjira...',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  // Logo/Branding
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(25), shape: BoxShape.circle),
                    child: const Icon(Icons.shield_outlined, size: 40, color: ImboniColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('Imboni', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: ImboniColors.primary), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text("Iboni y'ubuyobozi bwiza", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  
                  // Phone field
                  Text('Nimero ya telefoni', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '07X XXX XXXX', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => (v == null || v.length < 10) ? 'Nimero ya telefoni ntabwo yuzuye' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Password field
                  Text('Ijambo ry\'ibanga', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Ijambo ry\'ibanga rigomba kuba nibura inyuguti 6' : null,
                  ),
                  const SizedBox(height: 32),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: _login,
                    child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Kwinjira', style: TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(height: 16),
                  
                  // Register link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Nta konti ufite? ", style: theme.textTheme.bodyMedium),
                    TextButton(onPressed: widget.onRegisterTap, child: const Text('Iyandikishe')),
                  ]),
                ],
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
      final response = await authService.login(_phoneController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (response.isSuccess) {
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? 'Kwinjira byanze'), backgroundColor: ImboniColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Personal info header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.person_outline, color: ImboniColors.primary),
            const SizedBox(width: 12),
            Text('Amakuru y\'umuntu', style: theme.textTheme.titleMedium?.copyWith(color: ImboniColors.primary)),
          ]),
        ),
        const SizedBox(height: 24),

        // Full name
        Text('Amazina yombi', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _namesController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Izina ry\'mbere n\'Izina ry\'umuryango', prefixIcon: Icon(Icons.badge_outlined)),
          validator: (v) => (v == null || v.trim().split(' ').length < 2) ? 'Andika amazina yombi' : null,
        ),
        const SizedBox(height: 24),

        // Phone
        Text('Nimero ya telefoni', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '07X XXX XXXX', prefixIcon: Icon(Icons.phone_outlined)),
          validator: (v) => (v == null || v.length < 10) ? 'Nimero ya telefoni ntabwo yuzuye' : null,
        ),
        const SizedBox(height: 24),

        // National ID
        Text('Indangamuntu', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nationalIdController,
          keyboardType: TextInputType.number,
          maxLength: 16,
          decoration: const InputDecoration(hintText: '1 XXXX X XXXXXXX X XX', prefixIcon: Icon(Icons.badge_outlined), counterText: ''),
          validator: (v) => (v == null || v.length < 16) ? 'Indangamuntu igomba kuba imibare 16' : null,
        ),
        const SizedBox(height: 24),

        // Password
        Text('Ijambo ry\'ibanga', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Nibura inyuguti 6',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => (v == null || v.length < 6) ? 'Ijambo ry\'ibanga rigomba kuba nibura inyuguti 6' : null,
        ),
        const SizedBox(height: 24),

        // Confirm password
        Text('Emeza ijambo ry\'ibanga', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Subiramo ijambo ry\'ibanga', prefixIcon: Icon(Icons.lock_outlined)),
          validator: (v) => (v != _passwordController.text) ? 'Amazina y\'ibanga ntabwo ahura' : null,
        ),
        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) setState(() => _currentStep = 1);
          },
          child: const Text('Komeza'),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Usanzwe ufite konti? ", style: theme.textTheme.bodyMedium),
          TextButton(onPressed: widget.onLoginTap, child: const Text('Injira')),
        ]),
      ]),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Location header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ImboniColors.secondary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.location_on_outlined, color: ImboniColors.secondary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aho utuye', style: theme.textTheme.titleMedium?.copyWith(color: ImboniColors.secondary)),
              Text('Hitamo intara, akarere, umurenge, akagari, n\'umudugudu', style: theme.textTheme.bodySmall),
            ])),
          ]),
        ),
        const SizedBox(height: 24),

        LocationSelector(
          initialSelection: _location,
          onLocationChanged: (loc) => setState(() => _location = loc),
        ),
        const SizedBox(height: 32),

        if (_location.isComplete)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ImboniColors.success.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: ImboniColors.success.withAlpha(75))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.check_circle, color: ImboniColors.success, size: 20),
                const SizedBox(width: 8),
                Text('Aho utuye', style: theme.textTheme.labelLarge?.copyWith(color: ImboniColors.success)),
              ]),
              const SizedBox(height: 8),
              Text(_location.fullAddress, style: theme.textTheme.bodyMedium),
            ]),
          ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _location.isComplete ? _register : null,
          child: const Text('Kwiyandikisha'),
        ),
      ]),
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await authService.register(
        phone: _phoneController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kwiyandikisha byagenze neza!'), backgroundColor: ImboniColors.success));
        widget.onRegisterSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? 'Kwiyandikisha byanze'), backgroundColor: ImboniColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
