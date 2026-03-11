import 'package:flutter/material.dart';
import '../models/institution_models.dart';
import '../services/institution_service.dart';
import '../../shared/theme/colors.dart';

/// Citizen screen to submit a request to an institution
class InstitutionRequestScreen extends StatefulWidget {
  const InstitutionRequestScreen({super.key});

  @override
  State<InstitutionRequestScreen> createState() => _InstitutionRequestScreenState();
}

class _InstitutionRequestScreenState extends State<InstitutionRequestScreen> {
  int _currentStep = 0;

  // Data loaded from API
  List<InstitutionTypeModel> _types = [];
  List<InstitutionModel> _institutions = [];
  List<InstitutionBranchModel> _branches = [];
  List<InstitutionServiceModel> _services = [];
  List<InstitutionRequestModel> _myRequests = [];

  // Selected values
  String? _selectedTypeId;
  String? _selectedInstitutionId;
  String? _selectedBranchId;
  String? _selectedServiceId;
  String _selectedPriority = 'NORMAL';

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showMyRequests = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _loadMyRequests();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    final result = await institutionService.getTypes();
    if (mounted) {
      setState(() {
        _types = result.data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInstitutions(String typeId) async {
    final result = await institutionService.getInstitutions(typeId: typeId);
    if (mounted) setState(() => _institutions = result.data ?? []);
  }

  Future<void> _loadBranches(String institutionId) async {
    final result = await institutionService.getBranches(institutionId);
    if (mounted) setState(() => _branches = result.data ?? []);
  }

  Future<void> _loadServices(String institutionId) async {
    final result = await institutionService.getServices(institutionId);
    if (mounted) setState(() => _services = result.data ?? []);
  }

  Future<void> _loadMyRequests() async {
    final result = await institutionService.getMyRequests();
    if (mounted) setState(() => _myRequests = result.data ?? []);
  }

  Future<void> _submitRequest() async {
    if (_selectedInstitutionId == null || _selectedBranchId == null ||
        _selectedServiceId == null || _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await institutionService.submitRequest({
      'institutionId': _selectedInstitutionId,
      'branchId': _selectedBranchId,
      'serviceId': _selectedServiceId,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'priority': _selectedPriority,
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!'), backgroundColor: ImboniColors.success),
        );
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _currentStep = 0;
          _selectedTypeId = null;
          _selectedInstitutionId = null;
          _selectedBranchId = null;
          _selectedServiceId = null;
        });
        _loadMyRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Submission failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institution Services'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showMyRequests = !_showMyRequests),
            icon: Icon(_showMyRequests ? Icons.add_circle_outline : Icons.list_alt),
            label: Text(_showMyRequests ? 'New Request' : 'My Requests'),
          ),
        ],
      ),
      body: _showMyRequests ? _buildMyRequests(theme) : _buildRequestForm(theme),
    );
  }

  Widget _buildRequestForm(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep < 3) {
          setState(() => _currentStep++);
        } else {
          _submitRequest();
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) setState(() => _currentStep--);
      },
      controlsBuilder: (context, details) {
        final isLastStep = _currentStep == 3;
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _isSubmitting ? null : details.onStepContinue,
                style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.primary, foregroundColor: Colors.white),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isLastStep ? 'Submit Request' : 'Continue'),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
              ],
            ],
          ),
        );
      },
      steps: [
        // Step 1: Select Type & Institution
        Step(
          title: const Text('Select Institution'),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTypeId,
                decoration: const InputDecoration(labelText: 'Institution Type', border: OutlineInputBorder()),
                items: _types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.displayName))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedTypeId = v;
                    _selectedInstitutionId = null;
                    _institutions = [];
                  });
                  if (v != null) _loadInstitutions(v);
                },
              ),
              const SizedBox(height: 16),
              if (_institutions.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedInstitutionId,
                  decoration: const InputDecoration(labelText: 'Select Institution', border: OutlineInputBorder()),
                  items: _institutions.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedInstitutionId = v;
                      _selectedBranchId = null;
                      _selectedServiceId = null;
                      _branches = [];
                      _services = [];
                    });
                    if (v != null) {
                      _loadBranches(v);
                      _loadServices(v);
                    }
                  },
                ),
            ],
          ),
        ),

        // Step 2: Select Branch & Service
        Step(
          title: const Text('Select Branch & Service'),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_branches.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(labelText: 'Select Branch', border: OutlineInputBorder()),
                  items: _branches.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.branchName} (${b.district})'))).toList(),
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                )
              else
                const Text('No branches available. Select an institution first.'),
              const SizedBox(height: 16),
              if (_services.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedServiceId,
                  decoration: const InputDecoration(labelText: 'Select Service', border: OutlineInputBorder()),
                  items: _services.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.serviceName),
                        if (s.processingDays != null)
                          Text('Processing: ${s.processingDays} days', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedServiceId = v),
                ),
            ],
          ),
        ),

        // Step 3: Request Details
        Step(
          title: const Text('Request Details'),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          content: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Request Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                ],
                onChanged: (v) => setState(() => _selectedPriority = v ?? 'NORMAL'),
              ),
            ],
          ),
        ),

        // Step 4: Review
        Step(
          title: const Text('Review & Submit'),
          isActive: _currentStep >= 3,
          content: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review your request:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _ReviewRow(label: 'Institution', value: _institutions.where((i) => i.id == _selectedInstitutionId).firstOrNull?.name ?? '-'),
                  _ReviewRow(label: 'Branch', value: _branches.where((b) => b.id == _selectedBranchId).firstOrNull?.branchName ?? '-'),
                  _ReviewRow(label: 'Service', value: _services.where((s) => s.id == _selectedServiceId).firstOrNull?.serviceName ?? '-'),
                  _ReviewRow(label: 'Title', value: _titleController.text),
                  _ReviewRow(label: 'Priority', value: _selectedPriority),
                  const SizedBox(height: 8),
                  Text('Description:', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  Text(_descriptionController.text),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRequests(ThemeData theme) {
    if (_myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.hintColor.withAlpha(60)),
            const SizedBox(height: 16),
            Text('No requests yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final req = _myRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(req.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                      _StatusChip(status: req.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (req.institutionName != null)
                    Text(req.institutionName!, style: theme.textTheme.bodySmall?.copyWith(color: ImboniColors.primary)),
                  if (req.branchName != null)
                    Text('Branch: ${req.branchName!}', style: theme.textTheme.bodySmall),
                  if (req.serviceName != null)
                    Text('Service: ${req.serviceName!}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(req.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Submitted: ${_formatDate(req.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      _PriorityChip(priority: req.priority),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RequestStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case RequestStatus.submitted: return Colors.blue;
      case RequestStatus.received: return Colors.teal;
      case RequestStatus.underReview: return Colors.orange;
      case RequestStatus.investigation: return Colors.deepOrange;
      case RequestStatus.resolved: return ImboniColors.success;
      case RequestStatus.escalated: return Colors.red;
      case RequestStatus.rejected: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final RequestPriority priority;
  const _PriorityChip({required this.priority});

  Color get _color {
    switch (priority) {
      case RequestPriority.low: return Colors.grey;
      case RequestPriority.normal: return Colors.blue;
      case RequestPriority.high: return Colors.orange;
      case RequestPriority.urgent: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: _color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(priority.name.toUpperCase(), style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
