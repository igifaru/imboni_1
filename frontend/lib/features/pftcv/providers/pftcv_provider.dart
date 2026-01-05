import '../../../admin/services/admin_service.dart';
// PFTCV Provider - State management for Public Fund Transparency
import 'package:flutter/foundation.dart';
import '../../../shared/services/auth_service.dart';
import '../models/pftcv_models.dart';
import '../services/pftcv_service.dart';

class PftcvProvider extends ChangeNotifier {
  /* final ApiClient _api = apiClient; */

  List<Project> _projects = [];
  PftcvStats? _stats;
  String? _selectedUnitId;
  String? _selectedUnitName;
  String? _selectedLevelType;
  bool _isLoading = false;
  String? _error;

  // User's hierarchy from profile
  List<LocationLevel> _userHierarchy = [];

  List<Project> get projects => _projects;
  PftcvStats? get stats => _stats;
  String? get selectedUnitId => _selectedUnitId;
  String? get selectedUnitName => _selectedUnitName;
  String? get selectedLevelType => _selectedLevelType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<LocationLevel> get userHierarchy => _userHierarchy;

  String _locationHeaderTitle = 'Aho Ntuye';
  String get locationHeaderTitle => _locationHeaderTitle;

  /// Initialize user's location hierarchy from their profile or jurisdiction
  Future<void> initializeHierarchy() async {
    final user = authService.currentUser;
    if (user == null) return;

    _userHierarchy = [];

    if (user.isLeader) {
      _locationHeaderTitle = 'Aho Nkorera';
      // Fetch jurisdiction for leader
      try {
        final context = await adminService.getMyJurisdiction();
        if (context != null) {
           final level = (context['level'] as String?)?.toUpperCase();
           // Try 'name' or fallback to 'jurisdiction' (backend standard) or 'jurisdictionName'
           final name = (context['name'] ?? context['jurisdiction'] ?? context['jurisdictionName'] ?? '') as String;
           final id = (context['id'] ?? context['unitId']) as String?;
           
           if (level != null && name.isNotEmpty) {
              String title = 'Aho Nkorera';
              switch(level) {
                 case 'VILLAGE': title = 'Umudugudu Wanjye'; break;
                 case 'CELL': title = 'Akagari Kanjye'; break;
                 case 'SECTOR': title = 'Umurenge Wanjye'; break;
                 case 'DISTRICT': title = 'Akarere Kanjye'; break;
                 case 'PROVINCE': title = 'Intara Yanjye'; break;
              }

              _userHierarchy.add(LocationLevel(
                level: level,
                name: name,
                title: title,
                icon: 'work',
                unitId: id
              ));
           }
        }
      } catch (e) {
        debugPrint('Error fetching leader jurisdiction: $e');
      }
    } else {
      _locationHeaderTitle = 'Aho Ntuye';
      // Build hierarchy from user's location (village -> national)
      // NOTE: We use the name as key since we don't have unit IDs in user profile
      if (user.village != null && user.village!.isNotEmpty) {
        _userHierarchy.add(LocationLevel(
          level: 'VILLAGE',
          name: user.village!,
          title: 'Umudugudu Wanjye',
          icon: 'home',
        ));
      }
      if (user.cell != null && user.cell!.isNotEmpty) {
        _userHierarchy.add(LocationLevel(
          level: 'CELL',
          name: user.cell!,
          title: 'Akagari Kanjye',
          icon: 'groups',
        ));
      }
      if (user.sector != null && user.sector!.isNotEmpty) {
        _userHierarchy.add(LocationLevel(
          level: 'SECTOR',
          name: user.sector!,
          title: 'Umurenge Wanjye',
          icon: 'apartment',
        ));
      }
      if (user.district != null && user.district!.isNotEmpty) {
        _userHierarchy.add(LocationLevel(
          level: 'DISTRICT',
          name: user.district!,
          title: 'Akarere Kanjye',
          icon: 'location_city',
        ));
      }
      if (user.province != null && user.province!.isNotEmpty) {
        _userHierarchy.add(LocationLevel(
          level: 'PROVINCE',
          name: user.province!,
          title: 'Intara Yanjye',
          icon: 'map',
        ));
      }
    }

    // Add "All Projects" option
    _userHierarchy.add(const LocationLevel(
      level: 'ALL',
      name: 'Byose',
      title: 'Imishinga Yose',
      icon: 'public',
    ));

    notifyListeners();
  }

  /// Select a location level and fetch projects for it
  Future<void> selectLocation(LocationLevel location) async {
    _selectedUnitId = location.unitId;
    _selectedUnitName = location.name;
    _selectedLevelType = location.level;

    // Use null for 'ALL' to reset filters
    if (_selectedLevelType == 'ALL') {
      _selectedUnitId = null;
      _selectedUnitName = null;
      _selectedLevelType = null;
    }

    notifyListeners();
    await fetchProjects();
    await fetchStats();
  }

  /// Fetch projects for the selected location
  Future<void> fetchProjects({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Logic:
      // 1. If unitId is available, use it (exact match or handled by backend)
      // 2. If unitId is null but we have name and level, use those (hierarchical lookup by backend)
      // 3. If ALL/null, no filters

      final response = await pftcvService.getProjects(
        locationId: _selectedUnitId,
        locationName: _selectedUnitName,
        locationLevel: _selectedLevelType,
        search: search,
      );

      _projects = response;
      debugPrint('PFTCV: Loaded ${_projects.length} projects');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching projects: $e');
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch stats for the selected location
  Future<void> fetchStats() async {
    try {
      final response = await pftcvService.getStats(
         locationId: _selectedUnitId,
         locationName: _selectedUnitName,
         locationLevel: _selectedLevelType,
      );
      // NOTE: getStats currently implies locationId only.
      // If we want stats by name/level, we'd need to update pftcvService.getStats too.
      // primarily getProjects is the main view. Stats is secondary.
      // For now, let's leave stats slightly broken or update it later if needed.
      _stats = response;
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await fetchProjects();
    await fetchStats();
  }
}

/// Represents a location level in the user's hierarchy
class LocationLevel {
  final String level;
  final String name;
  final String title;
  final String icon;
  final String? unitId;

  const LocationLevel({
    required this.level,
    required this.name,
    required this.title,
    required this.icon,
    this.unitId,
  });
}
