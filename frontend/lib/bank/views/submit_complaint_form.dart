import 'package:flutter/material.dart';
import '../models/bank_models.dart';
import '../services/bank_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';

class SubmitBankComplaintScreen extends StatefulWidget {
  final BankModel bank;
  const SubmitBankComplaintScreen({super.key, required this.bank});

  @override
  State<SubmitBankComplaintScreen> createState() => _SubmitBankComplaintScreenState();
}

class _SubmitBankComplaintScreenState extends State<SubmitBankComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  List<BranchModel> _branches = [];
  List<BankServiceModel> _services = [];
  bool _isLoading = true;

  String? _selectedBranchId;
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    _loadBankData();
  }

  Future<void> _loadBankData() async {
    final response = await BankService.instance.getBankDetails(widget.bank.id);
    if (response.isSuccess && mounted) {
      setState(() {
        _branches = (response.data?['branches'] as List?)?.map((j) => BranchModel.fromJson(j)).toList() ?? [];
        _services = (response.data?['services'] as List?)?.map((j) => BankServiceModel.fromJson(j)).toList() ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _selectedBranchId == null || _selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }

    setState(() => _isLoading = true);
    final result = await BankService.instance.submitComplaint({
      'bankId': widget.bank.id,
      'branchId': _selectedBranchId,
      'serviceId': _selectedServiceId,
      'description': _descriptionController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.isSuccess) {
        _showSuccessDialog(result.data!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? l10n.submissionFailed)));
      }
    }
  }

  void _showSuccessDialog(BankCaseModel caseModel) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.complaintSubmittedSuccess, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('${l10n.referenceCode}: ${caseModel.caseReference}', style: const TextStyle(color: ImboniColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.saveTrackingHint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Form
            },
            child: Text(l10n.backToHome),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.reportTo} ${widget.bank.bankName}')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bankCaseDetails, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    // Branch Selection
                    _buildSectionHeader('1. ${l10n.selectBranch}'),
                    DropdownButtonFormField<String>(
                      value: _selectedBranchId,
                      items: _branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.branchName))).toList(),
                      onChanged: (v) => setState(() => _selectedBranchId = v),
                      decoration: InputDecoration(labelText: l10n.branchNameLabel, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    // Service Selection
                    _buildSectionHeader('2. ${l10n.serviceCategory}'),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceId,
                      items: _services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.serviceName))).toList(),
                      onChanged: (v) => setState(() => _selectedServiceId = v),
                      decoration: InputDecoration(labelText: l10n.serviceExampleHint, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    _buildSectionHeader('3. ${l10n.describeIssueHint}'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      validator: (v) => v == null || v.isEmpty ? l10n.describeIssue : null,
                      decoration: InputDecoration(
                        hintText: l10n.enterDetailsHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ImboniColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.submitComplaint, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
    );
  }
}
