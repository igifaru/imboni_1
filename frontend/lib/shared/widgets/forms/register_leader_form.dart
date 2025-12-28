
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
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _startDateController = TextEditingController();
  
  String? _selectedUnitName;
  String? _selectedRole;
  List<String> _availableChildren = [];
  String _targetLevel = 'PROVINCE';
  String _parentJurisdiction = 'Rwanda';
  
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _generatePassword();
    _startDateController.text = _formatDate(DateTime.now());
  }

  void _generatePassword() {
    // Simple random password generator for demo/default
    final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    // Simple implementation for the "Imb@2025#XyZ" style from Figma
    _passwordController.text = 'Imb@${DateTime.now().year}#${(rnd % 999).toString().padLeft(3, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ImboniColors.primary,
              onPrimary: Colors.white,
              surface: ImboniColors.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = _formatDate(picked);
      });
    }
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
            backgroundColor: ImboniColors.success
          ),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _nationalIdController.clear();
        _phoneController.clear();
        _generatePassword();
        setState(() => _selectedUnitName = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminService.error ?? 'Registration failed'), backgroundColor: ImboniColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _startDateController.dispose();
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
            Icon(Icons.error_outline, size: 48, color: ImboniColors.error),
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
          // Header
          Text(
            'Register New Leader', 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(
            'Ongeraho umuyobozi mushya muri sisitemu.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Form(
            key: _formKey,
            child: isDesktop 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPersonalInfoSection(theme)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildRoleLocationSection(theme)),
                  ],
                )
              : Column(
                  children: [
                    _buildPersonalInfoSection(theme),
                    const SizedBox(height: 32),
                    _buildRoleLocationSection(theme),
                  ],
                ),
          ),
          
          const SizedBox(height: 32),
          _buildSecuritySection(theme),
          
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                     _formKey.currentState!.reset();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reka'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: ImboniColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('✔ Emeza', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPersonalInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Amakuru Yihariye', theme),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant), 
          ),
          child: Column(
            children: [
              // Photo Upload
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amazina Yose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _buildTextField(
                          hint: 'Amazina Yose',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        Text('Urugero: Mugabo Jean', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: TextButton(onPressed: () {}, child: Text('Ongeraho Ifoto', style: TextStyle(color: Colors.grey[400])))),
              
              const SizedBox(height: 16),
              _buildLabel('Nimero y\'Indangamuntu'),
              _buildTextField(
                hint: '1 1990 8 0000000 0 00',
                controller: _nationalIdController,
                icon: Icons.badge_outlined,
                theme: theme,
              ),

              const SizedBox(height: 16),
              _buildLabel('Nimero ya Telefoni'),
              _buildTextField(
                hint: '+250 7X XXX XXXX',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                theme: theme,
              ),

              const SizedBox(height: 16),
              _buildLabel('Imell (Optional)'),
              _buildTextField(
                hint: 'email@example.com',
                controller: _emailController,
                icon: Icons.email_outlined,
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Inshingano n\'Aho Akorera', theme),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant), 
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Urwego rw\'Ubuyobozi'),
              _buildDropdown(
                value: _selectedRole,
                hint: 'Hitamo Urwego',
                icon: Icons.work_outline,
                items: ['Village Leader', 'Cell Executive', 'Sector Executive', 'District Mayor'],
                onChanged: (v) => setState(() => _selectedRole = v),
                theme: theme,
              ),
              Text('Hitamo Urwego (e.g., Village Leader, Cell Executive)', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),

              const SizedBox(height: 16),
              _buildLabel('Aho Akorera'),
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                 ),
                 child: Column(
                   children: [
                      Row(
                        children: [
                           Expanded(child: _buildLocationDropdown('Intara', _parentJurisdiction, null, theme, enabled: false)),
                           const SizedBox(width: 8),
                           Expanded(child: _buildLocationDropdown('Akarere', 'District', null, theme, enabled: false)),
                           const SizedBox(width: 8),
                           Expanded(child: _buildLocationDropdown('Umurenge', 'Sector', null, theme, enabled: false)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Dynamic selection based on current level
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: _selectedUnitName,
                              hint: _formatLevel(_targetLevel),
                              icon: Icons.location_on_outlined,
                              items: _availableChildren,
                              onChanged: (v) => setState(() => _selectedUnitName = v),
                              theme: theme,
                            )
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _buildLocationDropdown('Umudugudu', 'Village', null, theme, enabled: false)),
                        ],
                      ),
                   ],
                 ),
              ),
              
              const SizedBox(height: 16),
              _buildLabel('Itariki yatangiriyeho'),
              InkWell(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    hint: 'yatangiriyeho',
                    controller: _startDateController,
                    icon: Icons.calendar_today_outlined,
                    theme: theme,
                  ),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Umutekano na Status', theme),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant), 
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Ijambo ry\'Ibanga ry\'Agateganyo'),
                    _buildTextField(
                      hint: 'Password',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      theme: theme,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                        onPressed: () {}, // Implement copy
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Share this password. They must change it on first login.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Status ya Konti'),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_isActive ? 'Active' : 'Inactive', style: TextStyle(color: Colors.white)),
                      value: _isActive,
                      activeColor: ImboniColors.primary,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildLocationDropdown(String label, String hint, String? value, ThemeData theme, {bool enabled = true}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
           const SizedBox(height: 4),
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: theme.inputDecorationTheme.fillColor, 
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey),
             ),
             alignment: Alignment.centerLeft,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(hint, style: theme.textTheme.bodyMedium?.copyWith(
                    color: enabled ? null : theme.disabledColor
                 )),
                 Icon(Icons.keyboard_arrow_down, size: 20, color: theme.iconTheme.color),
               ],
             ),
           )
        ],
      );
  }


  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    required ThemeData theme,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    required ThemeData theme,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((name) => DropdownMenuItem(
        value: name,
        child: Text(name),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
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
}

