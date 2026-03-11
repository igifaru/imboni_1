import 'package:flutter/material.dart';
import '../models/bank_models.dart';
import '../services/bank_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';
import 'submit_complaint_form.dart'; // Real Form

class FinancialServicesScreen extends StatefulWidget {
  const FinancialServicesScreen({super.key});

  @override
  State<FinancialServicesScreen> createState() => _FinancialServicesScreenState();
}

class _FinancialServicesScreenState extends State<FinancialServicesScreen> {
  List<BankModel> _banks = [];
  List<BankCaseModel> _myComplaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      BankService.instance.getAllBanks(),
      BankService.instance.getMyComplaints(),
    ]);

    if (mounted) {
      setState(() {
        _banks = (results[0].data as List?)?.cast<BankModel>() ?? [];
        _myComplaints = (results[1].data as List?)?.cast<BankCaseModel>() ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.financialServices)),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                   _buildHeader(theme, l10n),
                   const SizedBox(height: 24),
                   _buildBankGrid(theme, l10n),
                   const SizedBox(height: 32),
                   _buildMyComplaints(theme, l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.secureBankingSupport, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.bankingSupportDesc, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildBankGrid(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectBank, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
          ),
          itemCount: _banks.length,
          itemBuilder: (context, index) => _BankButton(
            bank: _banks[index],
            onTap: () => _startComplaintFlow(_banks[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildMyComplaints(ThemeData theme, AppLocalizations l10n) {
    if (_myComplaints.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.myRecentComplaints, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._myComplaints.take(5).map((c) => _ComplaintTile(complaint: c)),
      ],
    );
  }

  void _startComplaintFlow(BankModel bank) {
    // Navigate to Complaint Submission Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubmitBankComplaintScreen(bank: bank)),
    );
  }
}

class _BankButton extends StatelessWidget {
  final BankModel bank;
  final VoidCallback onTap;

  const _BankButton({required this.bank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.account_balance, color: ImboniColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(bank.bankName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final BankCaseModel complaint;
  const _ComplaintTile({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(complaint.caseReference, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(complaint.bankName ?? l10n.bankComplaint),
        trailing: _StatusChip(status: complaint.status),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BankCaseStatus status;
  const _StatusChip({required this.status});

  String _getLabel(AppLocalizations l10n) {
    switch (status) {
      case BankCaseStatus.received: return l10n.statusReceived;
      case BankCaseStatus.underReview: return l10n.statusUnderReview;
      case BankCaseStatus.investigation: return l10n.statusInvestigation;
      case BankCaseStatus.resolved: return l10n.statusResolved;
      case BankCaseStatus.escalated: return l10n.statusEscalated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = status == BankCaseStatus.resolved ? ImboniColors.success : ImboniColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_getLabel(l10n), style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
