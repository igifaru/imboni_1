import 'package:flutter/material.dart';
import '../models/bank_models.dart';
import '../services/bank_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/dashboard/stat_card.dart';
import '../../shared/localization/app_localizations.dart';
import 'bank_details_screen.dart';

class BankManagementScreen extends StatefulWidget {
  const BankManagementScreen({super.key});

  @override
  State<BankManagementScreen> createState() => _BankManagementScreenState();
}

class _BankManagementScreenState extends State<BankManagementScreen> {
  List<BankModel> _banks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('BANK_MGMT: Initializing state...');
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    if (!mounted) return;
    debugPrint('BANK_MGMT: Fetching banks...');
    setState(() => _isLoading = true);
    try {
      final response = await BankService.instance.getAllBanks();
      if (mounted) {
        if (response.isSuccess) {
          setState(() {
            _banks = response.data ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to load banks')),
          );
        }
      }
    } catch (e) {
      debugPrint('BANK_MGMT_ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddBankDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final locationController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.registerNewBank),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.bankName)),
              TextField(controller: codeController, decoration: InputDecoration(labelText: l10n.bankCode)),
              TextField(controller: locationController, decoration: InputDecoration(labelText: l10n.headOfficeLocationLabel)),
              TextField(controller: emailController, decoration: InputDecoration(labelText: l10n.contactEmail)),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: l10n.contactPhone)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final result = await BankService.instance.registerBank({
                'bankName': nameController.text,
                'bankCode': codeController.text,
                'headOfficeLocation': locationController.text,
                'contactEmail': emailController.text,
                'contactPhone': phoneController.text,
              });
              if (result.isSuccess) {
                Navigator.pop(context);
                _loadBanks();
              }
            },
            child: Text(l10n.register),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final totalBanks = _banks.length;
    final totalBranches = _banks.fold(0, (sum, b) => sum + (b.branchCount));

    return Material(
      color: Colors.transparent,
      child: RefreshIndicator(
        onRefresh: _loadBanks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).bankManagement, 
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddBankDialog,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context).addBank),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ImboniColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_isLoading && _banks.isEmpty)
                const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()))
              else ...[
                // Stats Row
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.account_balance, 
                          iconColor: ImboniColors.primary, 
                          label: AppLocalizations.of(context).totalBanks, 
                          value: totalBanks.toString(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          icon: Icons.location_on, 
                          iconColor: ImboniColors.success, 
                          label: AppLocalizations.of(context).activeBranches, 
                          value: totalBranches.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // The Grid/Empty State
                _banks.isEmpty
                    ? _buildEmptyState(theme, textTheme)
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          mainAxisExtent: 220,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: _banks.length,
                        itemBuilder: (context, index) {
                          final bank = _banks[index];
                          return _BankCard(
                            bank: bank, 
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BankDetailsScreen(bank: bank)),
                            ),
                          );
                        },
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, TextTheme textTheme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, 
                 size: 80, color: theme.hintColor.withAlpha(50)),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noBanksYet, 
              style: textTheme.titleLarge?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).addBankHint,
              style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final BankModel bank;
  final VoidCallback onTap;
  const _BankCard({required this.bank, required this.onTap});

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
                    child: const Icon(Icons.account_balance, color: ImboniColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bank.bankName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${AppLocalizations.of(context).bankCodeLabel}: ${bank.bankCode}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  _StatusBadge(status: bank.status),
                ],
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.location_on_outlined, label: bank.headOfficeLocation),
              _InfoRow(icon: Icons.call_outlined, label: bank.contactPhone ?? 'No phone'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${bank.branchCount} ${AppLocalizations.of(context).activeBranches}', style: theme.textTheme.bodyMedium?.copyWith(color: ImboniColors.primary, fontWeight: FontWeight.w600)),
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

class _StatusBadge extends StatelessWidget {
  final BankStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final isActive = status == BankStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? ImboniColors.success : Colors.grey).withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? AppLocalizations.of(context).active : AppLocalizations.of(context).inactive,
        style: TextStyle(color: isActive ? ImboniColors.success : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
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
