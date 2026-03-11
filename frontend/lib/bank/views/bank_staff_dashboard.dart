import 'package:flutter/material.dart';
import '../models/bank_models.dart';
import '../services/bank_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/theme/responsive.dart';
import '../../shared/widgets/dashboard/stat_card.dart';

class BankStaffDashboard extends StatefulWidget {
  final String branchId;
  const BankStaffDashboard({super.key, required this.branchId});

  @override
  State<BankStaffDashboard> createState() => _BankStaffDashboardState();
}

class _BankStaffDashboardState extends State<BankStaffDashboard> {
  List<BankCaseModel> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    final response = await BankService.instance.getCasesByBranch(widget.branchId);
    if (response.isSuccess) {
      setState(() {
        _cases = response.data ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bank Branch Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCases),
      ]),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCases,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    Text('Inbound Complaints', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildCasesTable(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: StatCard(icon: Icons.new_releases, iconColor: ImboniColors.primary, label: 'Pending', value: _cases.where((c) => c.status == BankCaseStatus.received).length.toString())),
        const SizedBox(width: 12),
        Expanded(child: StatCard(icon: Icons.search, iconColor: ImboniColors.warning, label: 'Investigation', value: _cases.where((c) => c.status == BankCaseStatus.investigation).length.toString())),
        const SizedBox(width: 12),
        Expanded(child: StatCard(icon: Icons.check_circle, iconColor: ImboniColors.success, label: 'Resolved', value: _cases.where((c) => c.status == BankCaseStatus.resolved).length.toString())),
      ],
    );
  }

  Widget _buildCasesTable(ThemeData theme) {
    if (_cases.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No complaints for this branch.')));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Ref')),
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _cases.map((c) => DataRow(
            cells: [
              DataCell(Text(c.caseReference, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(c.serviceName ?? 'General')),
              DataCell(_StatusChip(status: c.status)),
              DataCell(TextButton(onPressed: () => _updateStatus(c), child: const Text('Manage'))),
            ],
          )).toList(),
        ),
      ),
    );
  }

  void _updateStatus(BankCaseModel caseModel) {
     showDialog(
       context: context,
       builder: (context) {
         String selectedStatus = 'UNDER_REVIEW';
         final notesController = TextEditingController();
         return AlertDialog(
           title: Text('Manage Case ${caseModel.caseReference}'),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               DropdownButtonFormField<String>(
                 value: selectedStatus,
                 items: const [
                    DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('Under Review')),
                    DropdownMenuItem(value: 'INVESTIGATION', child: Text('Investigation')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                    DropdownMenuItem(value: 'ESCALATED', child: Text('Escalate to HQ')),
                 ],
                 onChanged: (v) => selectedStatus = v!,
                 decoration: const InputDecoration(labelText: 'Status'),
               ),
               const SizedBox(height: 16),
               TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Action Notes')),
             ],
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
             ElevatedButton(
               onPressed: () async {
                 final res = await BankService.instance.updateCaseStatus(caseModel.id, selectedStatus, notes: notesController.text);
                 if (res.isSuccess) {
                   Navigator.pop(context);
                   _loadCases();
                 }
               },
               child: const Text('Confirm'),
             ),
           ],
         );
       }
     );
  }
}

class _StatusChip extends StatelessWidget {
  final BankCaseStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == BankCaseStatus.resolved ? ImboniColors.success : ImboniColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toString().split('.').last, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
