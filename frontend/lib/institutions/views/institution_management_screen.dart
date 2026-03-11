import 'package:flutter/material.dart';
import '../models/institution_models.dart';
import '../services/institution_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/dashboard/stat_card.dart';
import 'institution_details_screen.dart';

class InstitutionManagementScreen extends StatefulWidget {
  const InstitutionManagementScreen({super.key});

  @override
  State<InstitutionManagementScreen> createState() => _InstitutionManagementScreenState();
}

class _InstitutionManagementScreenState extends State<InstitutionManagementScreen> {
  List<InstitutionModel> _institutions = [];
  List<InstitutionTypeModel> _types = [];
  bool _isLoading = true;
  String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        institutionService.getTypes(),
        institutionService.getInstitutions(typeId: _selectedTypeId),
      ]);
      if (mounted) {
        setState(() {
          _types = (results[0].data as List<InstitutionTypeModel>?) ?? [];
          _institutions = (results[1].data as List<InstitutionModel>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('INSTITUTIONS_ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTypeDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Institution Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Type Name (e.g. BANK, INSURANCE)')),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await institutionService.createType({
                'name': nameController.text.toUpperCase(),
                'description': descController.text,
              });
              if (result.isSuccess) {
                Navigator.pop(context);
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRegisterInstitutionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final websiteController = TextEditingController();
    final locationController = TextEditingController();
    String? selectedTypeId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Register New Institution'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Institution Type'),
                    items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.displayName))).toList(),
                    onChanged: (v) => setDialogState(() => selectedTypeId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Institution Name')),
                  const SizedBox(height: 12),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  TextField(controller: websiteController, decoration: const InputDecoration(labelText: 'Website')),
                  const SizedBox(height: 12),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'HQ Location')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedTypeId == null ? null : () async {
                final result = await institutionService.registerInstitution({
                  'name': nameController.text,
                  'typeId': selectedTypeId,
                  'description': descController.text,
                  'email': emailController.text.isNotEmpty ? emailController.text : null,
                  'phone': phoneController.text.isNotEmpty ? phoneController.text : null,
                  'website': websiteController.text.isNotEmpty ? websiteController.text : null,
                  'hqLocation': locationController.text.isNotEmpty ? locationController.text : null,
                });
                if (result.isSuccess) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Institution registered successfully')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Institution Management', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showAddTypeDialog,
                        icon: const Icon(Icons.category, size: 18),
                        label: const Text('Add Type'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showRegisterInstitutionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Register Institution'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ImboniColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Type filter chips
              if (_types.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedTypeId == null,
                        onSelected: (_) {
                          setState(() => _selectedTypeId = null);
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._types.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(t.displayName),
                          selected: _selectedTypeId == t.id,
                          onSelected: (_) {
                            setState(() => _selectedTypeId = t.id);
                            _loadData();
                          },
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Stats
              if (!_isLoading) ...[
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.business,
                          iconColor: ImboniColors.primary,
                          label: 'Total Institutions',
                          value: _institutions.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          icon: Icons.category,
                          iconColor: ImboniColors.info,
                          label: 'Institution Types',
                          value: _types.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          icon: Icons.location_on,
                          iconColor: ImboniColors.success,
                          label: 'Total Branches',
                          value: _institutions.fold(0, (sum, i) => sum + i.branchCount).toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Loading / Empty / Grid
              if (_isLoading && _institutions.isEmpty)
                const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()))
              else if (_institutions.isEmpty)
                _buildEmptyState(theme, textTheme)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisExtent: 240,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _institutions.length,
                  itemBuilder: (context, index) {
                    final inst = _institutions[index];
                    return _InstitutionCard(
                      institution: inst,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InstitutionDetailsScreen(institution: inst)),
                      ).then((_) => _loadData()),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80, color: theme.hintColor.withAlpha(50)),
          const SizedBox(height: 24),
          Text('No institutions registered yet', style: textTheme.titleLarge?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Use the "Register Institution" button to add one', style: textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

// ─── Institution Card Widget ─────────────────────────────────

class _InstitutionCard extends StatelessWidget {
  final InstitutionModel institution;
  final VoidCallback onTap;
  const _InstitutionCard({required this.institution, required this.onTap});

  IconData _iconForType(String? typeName) {
    switch (typeName?.toUpperCase()) {
      case 'BANK': return Icons.account_balance;
      case 'INSURANCE': return Icons.shield;
      case 'TELECOM': return Icons.cell_tower;
      case 'GOVERNMENT': return Icons.gavel;
      case 'HEALTHCARE': return Icons.local_hospital;
      default: return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ImboniColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForType(institution.type?.name), color: ImboniColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(institution.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(institution.type?.displayName ?? 'Unknown Type', style: theme.textTheme.bodySmall?.copyWith(color: ImboniColors.primary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (institution.isActive ? ImboniColors.success : Colors.grey).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      institution.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(color: institution.isActive ? ImboniColors.success : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 8),
              if (institution.hqLocation != null)
                _InfoRow(icon: Icons.location_on_outlined, label: institution.hqLocation!),
              if (institution.email != null)
                _InfoRow(icon: Icons.email_outlined, label: institution.email!),
              if (institution.phone != null)
                _InfoRow(icon: Icons.phone_outlined, label: institution.phone!),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${institution.branchCount} Branches', style: theme.textTheme.bodyMedium?.copyWith(color: ImboniColors.primary, fontWeight: FontWeight.w600)),
                  const Icon(Icons.arrow_forward, size: 16, color: ImboniColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
