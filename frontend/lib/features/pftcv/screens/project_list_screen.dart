/// Project List Screen - Public Fund Transparency
import 'package:flutter/material.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _selectedSector;
  String? _selectedRisk;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await pftcvService.getProjects(
        sector: _selectedSector,
        riskLevel: _selectedRisk,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) setState(() => _projects = projects);
    } catch (e) {
      debugPrint('Error loading projects: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openProjectDetail(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Imari ya Leta'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Shaka umushinga...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) {
                _searchQuery = value;
                _loadProjects();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Byose',
                    selected: _selectedSector == null && _selectedRisk == null,
                    onSelected: (_) => setState(() { _selectedSector = null; _selectedRisk = null; _loadProjects(); }),
                  ),
                  const SizedBox(width: 8),
                  ...ProjectSector.values.take(5).map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: s.label,
                      icon: s.icon,
                      selected: _selectedSector == s.name,
                      onSelected: (_) => setState(() { _selectedSector = s.name; _loadProjects(); }),
                    ),
                  )),
                  const SizedBox(width: 8),
                  ...RiskLevel.values.map((r) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: r.label,
                      color: r.color,
                      selected: _selectedRisk == r.name,
                      onSelected: (_) => setState(() { _selectedRisk = r.name; _loadProjects(); }),
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Project list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_off, size: 64, color: colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('Nta mushinga ubonetse', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProjects,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.4,
                              ),
                              itemCount: _projects.length,
                              itemBuilder: (context, index) => ProjectCard(
                                project: _projects[index],
                                onTap: () => _openProjectDetail(_projects[index]),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({required this.label, this.icon, this.color, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 4)],
          if (color != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4)],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
