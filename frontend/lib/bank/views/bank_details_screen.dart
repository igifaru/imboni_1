import 'package:flutter/material.dart';
import '../models/bank_models.dart';
import '../services/bank_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/localization/app_localizations.dart';

class BankDetailsScreen extends StatefulWidget {
  final BankModel bank;
  const BankDetailsScreen({super.key, required this.bank});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  List<BranchModel> _branches = [];
  List<BankServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final response = await BankService.instance.getBankDetails(widget.bank.id);
    if (response.isSuccess && mounted) {
      setState(() {
        _branches = (response.data?['branches'] as List?)?.map((j) => BranchModel.fromJson(j)).toList() ?? [];
        _services = (response.data?['services'] as List?)?.map((j) => BankServiceModel.fromJson(j)).toList() ?? [];
        _isLoading = false;
      });
    }
  }

  void _showAddServiceDialog() {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addBankService),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.serviceNameHint)),
            TextField(controller: descController, decoration: InputDecoration(labelText: l10n.description)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final result = await BankService.instance.addService(widget.bank.id, {
                'serviceName': nameController.text,
                'description': descController.text,
              });
              if (result.isSuccess) {
                Navigator.pop(context);
                _loadDetails();
              }
            },
            child: Text(l10n.addBtn),
          ),
        ],
      ),
    );
  }

  void _showAddBranchDialog() {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final districtController = TextEditingController();
    final sectorController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.registerNewBranch),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.branchNameLabel)),
              TextField(controller: districtController, decoration: InputDecoration(labelText: l10n.levelDistrict)),
              TextField(controller: sectorController, decoration: InputDecoration(labelText: l10n.levelSector)),
              TextField(controller: addressController, decoration: InputDecoration(labelText: l10n.detailedAddress)),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: l10n.branchPhone)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
               final result = await BankService.instance.addBranch(widget.bank.id, {
                 'branchName': nameController.text,
                 'district': districtController.text,
                 'sector': sectorController.text,
                 'address': addressController.text,
                 'contactPhone': phoneController.text,
               });
               if (result.isSuccess) {
                 Navigator.pop(context);
                 _loadDetails();
               }
            },
            child: Text(AppLocalizations.of(context).addBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.bank.bankName), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDetails),
      ]),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildHeader(theme),
                  TabBar(
                    indicatorColor: ImboniColors.primary,
                    labelColor: ImboniColors.primary,
                    tabs: [
                      Tab(text: AppLocalizations.of(context).branchesTab, icon: const Icon(Icons.location_on)),
                      Tab(text: AppLocalizations.of(context).serviceCatalogTab, icon: const Icon(Icons.category)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBranchList(theme),
                        _buildServiceList(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, size: 40, color: ImboniColors.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.bank.bankName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${AppLocalizations.of(context).hqLabel}: ${widget.bank.headOfficeLocation}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const Spacer(),
              _StatusBadge(status: widget.bank.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(AppLocalizations.of(context).authorizedBranches, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
               ElevatedButton.icon(
                 onPressed: _showAddBranchDialog,
                 icon: const Icon(Icons.add_location),
                 label: Text(AppLocalizations.of(context).newBranchBtn),
                 style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.primary, foregroundColor: Colors.white),
               ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _branches.length,
            itemBuilder: (context, index) {
              final b = _branches[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: ImboniColors.primary),
                title: Text(b.branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${b.district}, ${b.sector}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceList(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(AppLocalizations.of(context).registeredServices, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
               ElevatedButton.icon(
                 onPressed: _showAddServiceDialog,
                 icon: const Icon(Icons.add),
                 label: Text(AppLocalizations.of(context).addBankService),
                 style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.primary, foregroundColor: Colors.white),
               ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final s = _services[index];
              return SwitchListTile(
                secondary: const Icon(Icons.layers, color: ImboniColors.primary),
                title: Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.description ?? AppLocalizations.of(context).noDescription),
                value: s.enabled,
                activeColor: ImboniColors.primary,
                onChanged: (v) async {
                  final result = await BankService.instance.toggleService(s.id, v);
                  if (result.isSuccess) {
                    _loadDetails();
                  }
                },
              );
            },
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? ImboniColors.success : Colors.grey).withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isActive ? AppLocalizations.of(context).active : AppLocalizations.of(context).inactive, style: TextStyle(color: isActive ? ImboniColors.success : Colors.grey, fontWeight: FontWeight.bold)),
    );
  }
}
