import 'package:flutter/material.dart';
import '../models/institution_models.dart';
import '../services/institution_service.dart';
import '../../shared/theme/colors.dart';

class InstitutionDetailsScreen extends StatefulWidget {
  final InstitutionModel institution;
  const InstitutionDetailsScreen({super.key, required this.institution});

  @override
  State<InstitutionDetailsScreen> createState() => _InstitutionDetailsScreenState();
}

class _InstitutionDetailsScreenState extends State<InstitutionDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InstitutionBranchModel> _branches = [];
  List<InstitutionServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      institutionService.getBranches(widget.institution.id),
      institutionService.getServices(widget.institution.id),
    ]);
    if (mounted) {
      setState(() {
        _branches = (results[0].data as List<InstitutionBranchModel>?) ?? [];
        _services = (results[1].data as List<InstitutionServiceModel>?) ?? [];
        _isLoading = false;
      });
    }
  }

  void _showAddBranchDialog() {
    final nameCtrl = TextEditingController();
    final provinceCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final sectorCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Branch'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Branch Name')),
              const SizedBox(height: 12),
              TextField(controller: provinceCtrl, decoration: const InputDecoration(labelText: 'Province')),
              const SizedBox(height: 12),
              TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'District')),
              const SizedBox(height: 12),
              TextField(controller: sectorCtrl, decoration: const InputDecoration(labelText: 'Sector')),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await institutionService.addBranch({
                'institutionId': widget.institution.id,
                'branchName': nameCtrl.text,
                'province': provinceCtrl.text,
                'district': districtCtrl.text,
                'sector': sectorCtrl.text,
                'address': addressCtrl.text,
              });
              if (result.isSuccess) {
                Navigator.pop(context);
                _loadDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final daysCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Service'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: daysCtrl, decoration: const InputDecoration(labelText: 'Processing Days'), keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final result = await institutionService.addService({
                'institutionId': widget.institution.id,
                'serviceName': nameCtrl.text,
                'description': descCtrl.text,
                if (daysCtrl.text.isNotEmpty) 'processingDays': int.tryParse(daysCtrl.text),
              });
              if (result.isSuccess) {
                Navigator.pop(context);
                _loadDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Failed')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inst = widget.institution;

    return Scaffold(
      appBar: AppBar(
        title: Text(inst.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Branches'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(theme, inst),
                _buildBranches(theme),
                _buildServices(theme),
              ],
            ),
    );
  }

  Widget _buildOverview(ThemeData theme, InstitutionModel inst) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ImboniColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.business, color: ImboniColors.primary, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(inst.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          if (inst.type != null) Text(inst.type!.displayName, style: theme.textTheme.bodyLarge?.copyWith(color: ImboniColors.primary)),
                        ]),
                      ),
                    ],
                  ),
                  if (inst.description != null) ...[
                    const SizedBox(height: 24),
                    Text(inst.description!, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.location_on, label: 'HQ Location', value: inst.hqLocation ?? 'N/A'),
                  _DetailRow(icon: Icons.email, label: 'Email', value: inst.email ?? 'N/A'),
                  _DetailRow(icon: Icons.phone, label: 'Phone', value: inst.phone ?? 'N/A'),
                  _DetailRow(icon: Icons.language, label: 'Website', value: inst.website ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Icon(Icons.location_on, color: ImboniColors.primary, size: 32),
                      const SizedBox(height: 8),
                      Text('${_branches.length}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Branches', style: theme.textTheme.bodySmall),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Icon(Icons.miscellaneous_services, color: ImboniColors.info, size: 32),
                      const SizedBox(height: 8),
                      Text('${_services.length}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Services', style: theme.textTheme.bodySmall),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranches(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Branches (${_branches.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddBranchDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Branch'),
                style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _branches.isEmpty
              ? const Center(child: Text('No branches yet. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final b = _branches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on, color: ImboniColors.primary),
                        ),
                        title: Text(b.branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${b.district}, ${b.sector}\n${b.address}'),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ImboniColors.success.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Active', style: TextStyle(color: ImboniColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildServices(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Services (${_services.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddServiceDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Service'),
                style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _services.isEmpty
              ? const Center(child: Text('No services yet. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: ImboniColors.info.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.miscellaneous_services, color: ImboniColors.info),
                        ),
                        title: Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(s.description ?? 'No description'),
                        trailing: s.processingDays != null
                            ? Chip(label: Text('${s.processingDays} days'))
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
