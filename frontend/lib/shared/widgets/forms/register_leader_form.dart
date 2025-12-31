
import 'package:flutter/material.dart';
import '../../../admin/services/admin_service.dart';
import '../../theme/colors.dart';
import '../../localization/app_localizations.dart';
import 'package:flutter/services.dart';

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
  String? _generatedPassword;
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
    final rnd = DateTime.now().microsecondsSinceEpoch;
    // Simple implementation for the "Imb@2025#XyZ" style from Figma
    final newPass = 'Imb@${DateTime.now().year}#${(rnd % 999).toString().padLeft(3, '0')}';
    _passwordController.text = newPass;
    setState(() => _generatedPassword = newPass);
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
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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
            l10n.registerNewLeader, 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Text(
            l10n.registerNewLeaderDesc,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Form(
            key: _formKey,
            child: isDesktop 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPersonalInfoSection(theme, l10n)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildRoleLocationSection(theme, l10n)),
                  ],
                )
              : Column(
                  children: [
                    _buildPersonalInfoSection(theme, l10n),
                    const SizedBox(height: 32),
                    _buildRoleLocationSection(theme, l10n),
                  ],
                ),
          ),
          
          const SizedBox(height: 32),
          _buildSecuritySection(theme, l10n),
          
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
                  child: Text(l10n.cancel),
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
                    : Text('✔ ${l10n.confirm}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildPersonalInfoSection(ThemeData theme, AppLocalizations l10n) { // Added l10n
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.personalInfo, theme), // Pass l10n.personalInfo
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
                       color: theme.dividerColor.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_outlined, size: 40, color: theme.disabledColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded( // Fixed broken widget tree here
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.fullName),
                        _buildTextField(
                          hint: l10n.fullName,
                          controller: _nameController,
                          icon: Icons.person_outline,
                          validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.exampleName, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildLabel(l10n.nationalId),
              _buildTextField(
                hint: '1 1990 8 0000000 0 00',
                controller: _nationalIdController,
                icon: Icons.badge_outlined,
                theme: theme,
              ),

              const SizedBox(height: 16),
              _buildLabel(l10n.phoneNumber),
              _buildTextField(
                 hint: '+250 7X XXX XXXX',
                 controller: _phoneController,
                 icon: Icons.phone_outlined,
                 theme: theme,
              ),

              const SizedBox(height: 16),
              _buildLabel(l10n.emailOptional),
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

  Widget _buildRoleLocationSection(ThemeData theme, AppLocalizations l10n) {
    // Map roles to localized strings
    final Map<String, String> roleDisplayNames = {
      'VILLAGE': 'Umuyobozi w\'Umudugudu (Village Leader)',
      'CELL': 'Umunyamabanga Nshingwabikorwa w\'Akagari',
      'SECTOR': 'Umunyamabanga Nshingwabikorwa w\'Umurenge',
      'DISTRICT': 'Umuyobozi w\'Akarere (Mayor)',
    };
    
    // Reverse map for logic
    final Map<String, String> displayToKey = {
      'Umuyobozi w\'Umudugudu (Village Leader)': 'VILLAGE',
      'Umunyamabanga Nshingwabikorwa w\'Akagari': 'CELL',
      'Umunyamabanga Nshingwabikorwa w\'Umurenge': 'SECTOR',
      'Umuyobozi w\'Akarere (Mayor)': 'DISTRICT',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.roleAndLocation, theme),
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
              _buildLabel(l10n.leadershipRole),
              _buildDropdown(
                value: _selectedRole, // This stores the Display Name
                hint: l10n.selectRole,
                icon: Icons.work_outline,
                items: roleDisplayNames.values.toList(),
                onChanged: (val) {
                   final key = displayToKey[val];
                   _onRoleChanged(key); // Pass internal key logic
                   setState(() => _selectedRole = val);
                },
                theme: theme,
              ),
              Text(l10n.hintRoleSelect, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),

              const SizedBox(height: 16),
              _buildLabel(l10n.workLocation),
              _buildHierarchy(theme, l10n),
              _buildLabel(l10n.startDate),
              InkWell(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    hint: l10n.startDate,
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

  Widget _buildSecuritySection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.securityAndStatus, theme),
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
                    _buildLabel(l10n.tempPassword),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SelectableText(
                              _generatedPassword ?? 'Generating...', 
                              style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'Courier', fontWeight: FontWeight.bold)
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 20),
                            onPressed: () {
                              if (_generatedPassword != null) {
                                Clipboard.setData(ClipboardData(text: _generatedPassword!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(l10n.passwordCopied), backgroundColor: ImboniColors.success)
                                );
                              }
                            },
                            tooltip: l10n.copyPassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Share this password. They must change it on first login.', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.accountStatus),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(_isActive ? l10n.active : l10n.inactive, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Switch(
                          value: _isActive,
                          activeTrackColor: ImboniColors.primary,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
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
                 if (!enabled) Icon(Icons.lock, size: 16, color: theme.disabledColor)
                 else Icon(Icons.keyboard_arrow_down, size: 20, color: theme.iconTheme.color),
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
      initialValue: value,
      isExpanded: true,
      items: items.map((name) => DropdownMenuItem(
        value: name,
        child: Text(
          name, 
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
  
  Widget _buildHierarchy(ThemeData theme, AppLocalizations l10n) {
    // Determine the label for OUR (User's) level
    // We don't know our own level explicitly from `getMyJurisdiction` result directly in the UI state
    // BUT, we know `_targetLevel`. 
    // And logically:
    // If target is VILLAGE -> We are CELL
    // If target is CELL -> We are SECTOR
    // If target is SECTOR -> We are DISTRICT
    // If target is DISTRICT -> We are PROVINCE (or NATIONAL)
    
    // HOWEVER, correct labels should come from `_targetLevel` Logic.
    
    String parentLabel = 'Urwego rw\'Ibanze (Parent Level)';
    if (_targetLevel == 'VILLAGE') {
      parentLabel = 'Akagari (Cell)';
    } else if (_targetLevel == 'CELL') {
      parentLabel = 'Umurenge (Sector)';
    } else if (_targetLevel == 'SECTOR') {
      parentLabel = 'Akarere (District)';
    } else if (_targetLevel == 'DISTRICT') {
      parentLabel = 'Intara (Province)';
    }
    
    String targetLabel = _formatLevel(_targetLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
           // Row 1: Context (Where we are / Parent Unit)
           Row(
             children: [
                Expanded(
                  child: _buildLocationDropdown(
                    parentLabel, 
                    _parentJurisdiction, 
                    null, 
                    theme, 
                    enabled: false
                  )
                ),
             ],
           ),
           const SizedBox(height: 12),
           // Row 2: Target (What we are selecting)
           Row(
             children: [
               Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(targetLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      const SizedBox(height: 4),
                      _buildDropdown(
                        value: _selectedUnitName,
                        hint: 'Hitamo location',
                        icon: Icons.location_on_outlined,
                        items: _availableChildren,
                        onChanged: (v) => setState(() => _selectedUnitName = v),
                        theme: theme,
                      ),
                    ],
                  ),
               ),
             ],
           ),
        ],
      ),
    );
  }

  void _onRoleChanged(String? roleKey) {
    if (roleKey == null) return;
    setState(() {
      _targetLevel = roleKey;
      _selectedUnitName = null; // Reset selection when role changes
    });
  }

  String _formatLevel(String level) {
    switch (level) {
      case 'PROVINCE': return 'Intara (Province)';
      case 'DISTRICT': return 'Akarere (District)';
      case 'SECTOR': return 'Umurenge (Sector)';
      case 'CELL': return 'Akagari (Cell)';
      case 'VILLAGE': return 'Umudugudu (Village)';
      default: return level;
    }
  }
}

