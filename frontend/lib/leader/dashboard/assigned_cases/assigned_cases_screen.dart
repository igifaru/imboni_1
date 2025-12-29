import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/services/case_service.dart';
import '../../../shared/models/models.dart';
import '../../case_management/case_details_screen.dart';
import '../widgets/professional_case_card.dart';

class AssignedCasesScreen extends StatefulWidget {
  const AssignedCasesScreen({super.key});

  @override
  State<AssignedCasesScreen> createState() => _AssignedCasesScreenState();
}

class _AssignedCasesScreenState extends State<AssignedCasesScreen> {
  List<CaseModel> _cases = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Filters
  String _statusFilter = 'All';
  String _categoryFilter = 'All';
  String _priorityFilter = 'All';
  String _sortBy = 'Newest First';

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      final response = await caseService.getAssignedCases(limit: 50);
      if (mounted) {
        setState(() {
          _cases = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CaseModel> get _filteredCases {
    return _cases.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            c.caseReference.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All' || c.status == _statusFilter.toUpperCase().replaceAll(' ', '_');
      final matchesCategory = _categoryFilter == 'All' || c.category == _categoryFilter;
      final matchesPriority = _priorityFilter == 'All' || c.urgency == _priorityFilter.toUpperCase();

      return matchesSearch && matchesStatus && matchesCategory && matchesPriority;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Light grey background like screenshot
      body: SafeArea(
        child: Column(
          children: [
            // Header & Filters
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assigned Cases', 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)
                  ),
                  const SizedBox(height: 24),
                  
                  // Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Search
                        SizedBox(
                          width: 250,
                          child: TextField(
                             onChanged: (val) => setState(() => _searchQuery = val),
                             decoration: InputDecoration(
                               hintText: 'Search cases...',
                               prefixIcon: const Icon(Icons.search, color: Colors.grey),
                               isDense: true,
                               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                             ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Dropdowns
                        _buildDropdown('Status', ['All', 'Open', 'In Progress', 'Resolved', 'Escalated'], _statusFilter, (v) => setState(() => _statusFilter = v!)),
                        const SizedBox(width: 12),
                        _buildDropdown('Category', ['All', 'Justice', 'Health', 'Land', 'Social'], _categoryFilter, (v) => setState(() => _categoryFilter = v!)),
                        const SizedBox(width: 12),
                        _buildDropdown('Priority', ['All', 'Normal', 'High', 'Emergency'], _priorityFilter, (v) => setState(() => _priorityFilter = v!)),
                        
                        const SizedBox(width: 24),
                        // Sort (Push to right usually, but in scrollable row just append)
                        const Text('Sort by: ', style: TextStyle(color: Colors.grey)),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onChanged: (v) => setState(() => _sortBy = v!),
                          items: ['Newest First', 'Oldest First', 'Priority'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Grid
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredCases.isEmpty 
                  ? Center(child: Text("No cases found", style: TextStyle(color: Colors.grey[600])))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive logic: 1 column on mobile, 2 on tablet, 3 on wide
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 800) crossAxisCount = 2; // Tablet/Small Lap
                        if (constraints.maxWidth > 1200) crossAxisCount = 3; // Wide

                        return GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 300, // Increased height to prevent overflow
                          ),
                          itemCount: _filteredCases.length,
                          itemBuilder: (context, index) {
                             return ProfessionalCaseCard(
                               caseData: _filteredCases[index],
                               onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => LeaderCaseDetailsScreen(caseData: _filteredCases[index])),
                               ),
                             );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          DropdownButton<String>(
            value: currentValue,
            underline: const SizedBox(),
            isDense: false,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            onChanged: onChanged,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          ),
        ],
      ),
    );
  }
}
