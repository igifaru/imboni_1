
import 'package:flutter/material.dart';
import '../../../admin/services/admin_service.dart';
import '../../theme/colors.dart';
import '../../theme/responsive.dart';
import '../../constants/rwanda_provinces.dart';

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
  
  String? _selectedUnitName;
  List<String> _availableChildren = [];
  String _targetLevel = 'PROVINCE';
  String _parentJurisdiction = 'Rwanda';
  
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final context = await adminService.getMyJurisdiction();
      if (context != null && context['success'] == true) {
        if (mounted) {
          setState(() {
            _targetLevel = context['targetLevel'] ?? 'PROVINCE';
            _parentJurisdiction = context['jurisdiction'] ?? 'Rwanda';
            _availableChildren = List<String>.from(context['children'] ?? []);
            _isInitializing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _initError = adminService.error ?? 'Failed to load system context';
            _isInitializing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = 'Connection error: Could not reach server';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final success = await adminService.registerSubordinate(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      level: _targetLevel,
      jurisdictionName: _selectedUnitName!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Succesfully registered Head of $_selectedUnitName'), 
            backgroundColor: Colors.green
          ),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() => _selectedUnitName = null);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_initError!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadContext, child: const Text('Retry')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ImboniColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add, color: ImboniColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register ${_formatLevel(_targetLevel)} Leader', 
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    Text(
                      'Assigned under $_parentJurisdiction',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
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
                  icon: Icons.person_outline,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  validator: (v) => v?.isEmpty == true || !v!.contains('@') ? 'Invalid email' : null,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Initial Password',
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => v != null && v.length < 6 ? 'Min 6 characters' : null,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // Jurisdiction Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedUnitName,
                  items: _availableChildren.map((name) => DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedUnitName = v),
                  decoration: InputDecoration(
                    labelText: 'Select ${_formatLevel(_targetLevel)}',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.cardColor.withValues(alpha: 0.5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                  ),
                  validator: (v) => v == null ? 'Please select a unit' : null,
                  dropdownColor: theme.cardColor,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ImboniColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Complete Registration', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLevel(String level) {
    switch (level) {
      case 'PROVINCE': return 'Province';
      case 'DISTRICT': return 'District';
      case 'SECTOR': return 'Sector';
      case 'CELL': return 'Cell';
      case 'VILLAGE': return 'Village';
      default: return level;
    }
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
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.cardColor.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ImboniColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
