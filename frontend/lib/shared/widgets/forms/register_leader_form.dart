
import 'package:flutter/material.dart';
import '../../../admin/services/admin_service.dart';
import '../../theme/colors.dart';
import '../../theme/responsive.dart';

class RegisterLeaderForm extends StatefulWidget {
  const RegisterLeaderForm({super.key});

  @override
  State<RegisterLeaderForm> createState() => _RegisterLeaderFormState();
}

class _RegisterLeaderFormState extends State<RegisterLeaderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jurisdictionController = TextEditingController();
  
  String? _selectedLevel;
  final List<Map<String, String>> _levels = [
    {'value': 'PROVINCE', 'label': 'Province (Intara)'},
    {'value': 'DISTRICT', 'label': 'District (Akarere)'},
    {'value': 'SECTOR', 'label': 'Sector (Umurenge)'},
    {'value': 'CELL', 'label': 'Cell (Akagari)'},
    {'value': 'VILLAGE', 'label': 'Village (Umudugudu)'},
  ];
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final success = await adminService.registerSubordinate(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      level: _selectedLevel!,
      jurisdictionName: _jurisdictionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leader registered successfully'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _jurisdictionController.clear();
        setState(() => _selectedLevel = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminService.error ?? 'Registration failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _jurisdictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    // If desktop, use a contained width or padding. If mobile, full width.
    // The previous implementation used padding 40 for desktop, 20 for mobile.
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header styles adapted from both implementations
          Text('Register New Leader', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Register a subordinate leader for a specific administrative unit.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  icon: Icons.email,
                  validator: (v) => v?.isEmpty == true || !v!.contains('@') ? 'Invalid email' : null,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Initial Password',
                  controller: _passwordController,
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (v) => v != null && v.length < 6 ? 'Min 6 chars' : null,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedLevel,
                   items: _levels.map((l) => DropdownMenuItem(
                    value: l['value'],
                    child: Text(l['label']!),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedLevel = v),
                  decoration: InputDecoration(
                    labelText: 'Administrative Level',
                    prefixIcon: const Icon(Icons.layers),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  validator: (v) => v == null ? 'Required' : null,
                  dropdownColor: theme.cardColor,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Jurisdiction Name (e.g. Kigali, Gasabo)',
                  controller: _jurisdictionController,
                  icon: Icons.location_city,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  theme: theme,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ImboniColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register Leader', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        filled: true,
        fillColor: theme.cardColor.withAlpha(200).withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ImboniColors.primary),
        ),
      ),
    );
  }
}
