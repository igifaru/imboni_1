import 'package:flutter/material.dart';
import 'package:imboni/shared/services/case_service.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import '../../case_management/case_details_screen.dart';
import 'package:imboni/shared/widgets/professional_case_card.dart';

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
      // Use getJurisdictionCases to fetch all cases in leader's jurisdiction
      // This matches the dashboard stats and includes cases assigned to other leaders
      final response = await caseService.getJurisdictionCases(limit: 50);
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.colorScheme.surface : const Color(0xFFF5F6F8);
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: bgColor, 
      body: SafeArea(
        child: Column(
          children: [
            // Header & Filters
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.assignedCases, 
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                               hintText: l10n.searchHint,
                               prefixIcon: Icon(Icons.search, color: theme.hintColor),
                               isDense: true,
                               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                               enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                               filled: true,
                               fillColor: isDark ? Colors.white.withAlpha(10) : Colors.white,
                             ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Dropdowns
                        // NOTE: Keeping filter VALUES in English/Code for logic, but could localize labels if needed.
                        // Ideally, items should be localized. For now, we localize the Label ("Status", "Category")
                        _buildDropdown(context, l10n.status, ['All', 'Open', 'In Progress', 'Resolved', 'Escalated'], _statusFilter, (v) => setState(() => _statusFilter = v!), l10n),
                        const SizedBox(width: 12),
                        _buildDropdown(context, l10n.categoryLabel, ['All', 'Justice', 'Health', 'Land', 'Social'], _categoryFilter, (v) => setState(() => _categoryFilter = v!), l10n),
                        const SizedBox(width: 12),
                        _buildDropdown(context, l10n.priority, ['All', 'Normal', 'High', 'Emergency'], _priorityFilter, (v) => setState(() => _priorityFilter = v!), l10n),
                        
                        const SizedBox(width: 24),
                        // Sort
                        Text('${l10n.sortBy} ', style: TextStyle(color: theme.hintColor)),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          dropdownColor: theme.cardColor,
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onChanged: (v) => setState(() => _sortBy = v!),
                          items: ['Newest First', 'Oldest First', 'Priority'].map((e) {
                             // Map display values to localized
                             String displayWith = e;
                             if (e == 'Newest First') displayWith = l10n.sortNewest;
                             if (e == 'Oldest First') displayWith = l10n.sortOldest;
                             if (e == 'Priority') displayWith = l10n.sortPriority;
                             
                             return DropdownMenuItem(value: e, child: Text(displayWith));
                          }).toList(),
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
                  ? Center(child: Text(l10n.noCasesFound, style: TextStyle(color: theme.hintColor)))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive logic
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 800) crossAxisCount = 2; // Tablet/Small Lap
                        if (constraints.maxWidth > 1200) crossAxisCount = 3; // Wide

                        return GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 300, 
                          ),
                          itemCount: _filteredCases.length,
                          itemBuilder: (context, index) {
                             return ProfessionalCaseCard(
                               caseData: _filteredCases[index],
                              onTap: () async {
                                 // Navigate and wait for result
                                 final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => LeaderCaseDetailsScreen(caseData: _filteredCases[index])),
                                 );
                                 
                                 // If result is true or just on every return (safer), refresh the list
                                 // Checking if mounted to avoid errors if screen disposed
                                 if (mounted) {
                                   _loadCases();
                                 }
                               },
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

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String currentValue, ValueChanged<String?> onChanged, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.white.withAlpha(10) : Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: theme.hintColor, fontSize: 13)),
          DropdownButton<String>(
            value: currentValue,
            underline: const SizedBox(),
            isDense: false,
            dropdownColor: theme.cardColor,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500),
            onChanged: onChanged,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          ),
        ],
      ),
    );
  }
}
