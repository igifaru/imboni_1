// PFTCV Home Screen - Similar to Community with hierarchical location navigation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/colors.dart';
import '../providers/pftcv_provider.dart';
import '../models/pftcv_models.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';

class PftcvHomeScreen extends StatefulWidget {
  const PftcvHomeScreen({super.key});

  @override
  State<PftcvHomeScreen> createState() => _PftcvHomeScreenState();
}

class _PftcvHomeScreenState extends State<PftcvHomeScreen> {
  Project? _selectedProject;
  int _selectedLevelIndex = -1; // -1 means show welcome, 0+ means show projects for that level

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PftcvProvider>();
      provider.initializeHierarchy();
      // Auto-select "All Projects" to show data immediately
      final lastIndex = provider.userHierarchy.length - 1;
      if (lastIndex >= 0) {
        setState(() => _selectedLevelIndex = lastIndex);
        final loc = provider.userHierarchy[lastIndex];
        provider.selectLocation(loc);
      } else {
        provider.fetchProjects();
        provider.fetchStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imari ya Leta'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearch),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<PftcvProvider>().refresh()),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return isWide ? _buildWideLayout(context) : _buildMobileLayout(context);
        },
      ),
    );
  }

  // Wide screen layout with left panel (units) and right panel (content)
  Widget _buildWideLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Left Panel - Location Hierarchy
        Container(
          width: 320,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: colorScheme.outlineVariant.withAlpha(80))),
          ),
          child: Column(
            children: [
              _buildLocationHeader(theme),
              Expanded(child: _buildLocationList(context, isWide: true)),
            ],
          ),
        ),
        // Right Panel - Projects
        Expanded(
          child: _selectedLevelIndex < 0
              ? _buildWelcomePanel(context)
              : _selectedProject != null
                  ? ProjectDetailScreen(projectId: _selectedProject!.id, embedded: true, onBack: () => setState(() => _selectedProject = null))
                  : _buildProjectsGrid(context),
        ),
      ],
    );
  }

  // Mobile layout
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildLocationHeader(theme),
        Expanded(child: _buildLocationList(context, isWide: false)),
      ],
    );
  }

  Widget _buildLocationHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(80))),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: ImboniColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Aho Ntuye', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLocationList(BuildContext context, {required bool isWide}) {
    return Consumer<PftcvProvider>(
      builder: (context, provider, child) {
        if (provider.userHierarchy.isEmpty) {
          // Fallback if no profile location
          return _buildEmptyLocationState(context, provider);
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.userHierarchy.length,
            itemBuilder: (context, index) {
              final loc = provider.userHierarchy[index];
              return _buildLocationCard(context, loc, index, isWide: isWide);
            },
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(BuildContext context, LocationLevel loc, int index, {required bool isWide}) {
    final isSelected = _selectedLevelIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    switch (loc.icon) {
      case 'home': icon = Icons.home; break;
      case 'groups': icon = Icons.groups; break;
      case 'apartment': icon = Icons.apartment; break;
      case 'location_city': icon = Icons.location_city; break;
      case 'map': icon = Icons.map; break;
      default: icon = Icons.public;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isSelected ? ImboniColors.primary.withAlpha(26) : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isSelected ? ImboniColors.primary : colorScheme.outlineVariant.withAlpha(80), width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(26), shape: BoxShape.circle),
          child: Icon(icon, color: ImboniColors.primary, size: 20),
        ),
        title: Text(loc.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? ImboniColors.primary : null)),
        subtitle: Text(loc.name, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: isSelected ? ImboniColors.primary : Colors.grey, size: 20),
        onTap: () {
          setState(() => _selectedLevelIndex = index);
          context.read<PftcvProvider>().selectLocation(loc);
          if (!isWide) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => _ProjectListPage(levelName: loc.name)));
          }
        },
      ),
    );
  }

  Widget _buildEmptyLocationState(BuildContext context, PftcvProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(26), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, size: 48, color: ImboniColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Imari ya Leta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Reba imishinga yo mu gace kawe', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchProjects(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reba Byose'),
              style: ElevatedButton.styleFrom(backgroundColor: ImboniColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePanel(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: ImboniColors.primary.withAlpha(26), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance, size: 64, color: ImboniColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Hitamo Urwego', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Hitamo aho ushaka kureba imishinga', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsGrid(BuildContext context) {
    return Consumer<PftcvProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Nta mushinga ubonetse', style: Theme.of(context).textTheme.titleMedium),
                Text(provider.selectedUnitName ?? '', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            const aspectRatio = 1.0;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 600,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: aspectRatio,
              ),
              itemCount: provider.projects.length,
              itemBuilder: (context, index) {
                final project = provider.projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => setState(() => _selectedProject = project),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSearch() {
    showSearch(context: context, delegate: _ProjectSearchDelegate(context.read<PftcvProvider>()));
  }
}

// Separate page for mobile project list
class _ProjectListPage extends StatelessWidget {
  final String levelName;
  const _ProjectListPage({required this.levelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Imishinga - $levelName')),
      body: Consumer<PftcvProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.projects.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Nta mushinga ubonetse'),
            ]));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              const aspectRatio = 1.0;
              
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: provider.projects.length,
                itemBuilder: (context, index) {
                  final project = provider.projects[index];
                  return ProjectCard(
                    project: project,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Search delegate for projects
class _ProjectSearchDelegate extends SearchDelegate<Project?> {
  final PftcvProvider provider;
  _ProjectSearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final filtered = provider.projects.where((p) =>
      p.name.toLowerCase().contains(query.toLowerCase()) ||
      p.projectCode.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Nta mushinga ubonetse'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return ListTile(
          leading: Icon(p.sector.icon, color: ImboniColors.primary),
          title: Text(p.name),
          subtitle: Text(p.projectCode),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: p.riskLevel.color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
            child: Text(p.riskLevel.label, style: TextStyle(fontSize: 10, color: p.riskLevel.color)),
          ),
          onTap: () => close(context, p),
        );
      },
    );
  }
}
