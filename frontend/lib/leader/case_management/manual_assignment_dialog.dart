import 'package:flutter/material.dart';
import '../../../admin/services/admin_service.dart';
import '../../../shared/services/case_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/localization/app_localizations.dart';


class ManualAssignmentDialog extends StatefulWidget {
  final String caseId;
  final String administrativeUnitId;

  const ManualAssignmentDialog({
    super.key,
    required this.caseId,
    required this.administrativeUnitId,
  });

  @override
  State<ManualAssignmentDialog> createState() => _ManualAssignmentDialogState();
}

class _ManualAssignmentDialogState extends State<ManualAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  
  List<UserModel> _leaders = [];
  bool _isLoadingLeaders = true;
  String? _leaderError;
  
  String? _selectedLeaderId;
  DateTime? _selectedDeadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaders();
    // Default deadline to 48 hours
    _selectedDeadline = DateTime.now().add(const Duration(hours: 48));
  }

  Future<void> _fetchLeaders() async {
    try {
      // Fetch leaders for this specific unit
      // Note: This relies on adminService.getUsers supporting unitId filter
      final response = await adminService.getUsers(
        role: 'LEADER,ADMIN,OVERSIGHT',
        unitId: widget.administrativeUnitId,
        limit: 100, // Fetch all reasonable leaders for the unit
      );
      
      if (mounted) {
        setState(() {
          var list = response.data;
          final currentUser = authService.currentUser;

          if (currentUser != null) {
            // 1. Keep self in list to allow "Taking" the case
            // list = list.where((u) => u.id != currentUser.id).toList();

            // 2. If Staff (LEADER), hide Head (ADMIN/OVERSIGHT) and by Title
            if (currentUser.role == 'LEADER') {
              list = list.where((u) {
                // Remove if explicit Admin/Oversight role
                if (u.role == 'ADMIN' || u.role == 'OVERSIGHT') return false;
                
                // Remove if Title indicates Head/Chief
                final title = u.positionTitle?.toLowerCase() ?? '';
                const headKeywords = [
                  'head of', 'executive', 'manager', 'director', 
                  'umuyobozi w', 'ukuru w', 'perezida', 'chief'
                ];
                
                for (final keyword in headKeywords) {
                  if (title.contains(keyword)) return false;
                }
                
                return true;
              }).toList();
            }
          }

          _leaders = list;
          _isLoadingLeaders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderError = 'Failed to load leaders';
          _isLoadingLeaders = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaderId == null || _selectedDeadline == null) return;

    setState(() => _isSubmitting = true);

    final result = await caseService.assignCase(
      widget.caseId,
      _selectedLeaderId!,
      _selectedDeadline!,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result.isSuccess) {
        Navigator.pop(context, true); // Return true to refresh parent
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Assignment failed'),
            backgroundColor: ImboniColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      /* builder: (context, child) {
        // Use system theme
        return child!;
      }, */
    );
    
    if (picked != null) {
      // Pick time
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? now),
      );
      
      if (time != null && mounted) {
        setState(() {
          _selectedDeadline = DateTime(
            picked.year, picked.month, picked.day,
            time.hour, time.minute
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Hardcoded strings for now for speed, ideally localized ("Assign Case", "Select Leader", etc.)
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              l10n.assignCaseTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 24),

            _isLoadingLeaders
                ? const Center(child: CircularProgressIndicator())
                : _leaderError != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _leaderError!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.selectLeaderLabel,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              // value: _selectedLeaderId, // Deprecated, using initialValue
              initialValue: _selectedLeaderId,
                              dropdownColor: theme.colorScheme.surfaceContainerHighest,
                              decoration: InputDecoration(
                                hintText: l10n.chooseLeaderHint,
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: _leaders.map((user) {
                                String label = user.name ?? user.email ?? 'Unknown Leader';
                                if (user.positionTitle != null && user.positionTitle!.isNotEmpty) {
                                  label += ' — ${user.positionTitle}';
                                }
                                return DropdownMenuItem(
                                  value: user.id,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedLeaderId = val),
                              validator: (val) => val == null ? l10n.selectLeaderLabel : null,
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.setDeadlineLabel,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedDeadline != null
                                            ? '${_selectedDeadline!.year}-${_selectedDeadline!.month}-${_selectedDeadline!.day} ${_selectedDeadline!.hour}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}'
                                            : l10n.selectDateTime,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: _selectedDeadline != null
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_leaders.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.noActiveLeadersError,
                                          style: TextStyle(
                                              fontSize: 12, color: theme.colorScheme.onErrorContainer),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

            const SizedBox(height: 32),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _leaders.isEmpty ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ImboniColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(l10n.assignBtn, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
