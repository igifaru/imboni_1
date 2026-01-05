/// PFTCV Provider - State management for Public Fund Transparency
import 'package:flutter/foundation.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/auth_service.dart';
import '../models/pftcv_models.dart';

class PftcvProvider extends ChangeNotifier {
  final ApiClient _api = apiClient;

  List<Project> _projects = [];
  PftcvStats? _stats;
  String? _selectedUnitId;
  String? _selectedUnitName;
  bool _isLoading = false;
  String? _error;

  // User's hierarchy from profile
  List<LocationLevel> _userHierarchy = [];

  List<Project> get projects => _projects;
  PftcvStats? get stats => _stats;
  String? get selectedUnitId => _selectedUnitId;
  String? get selectedUnitName => _selectedUnitName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<LocationLevel> get userHierarchy => _userHierarchy;

  /// Initialize user's location hierarchy from their profile
  void initializeHierarchy() {
    final user = authService.currentUser;
    if (user == null) return;

    _userHierarchy = [];

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
  Future<void> selectLocation(String? unitId, String? unitName) async {
    _selectedUnitId = unitId;
    _selectedUnitName = unitName;
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
      final queryParams = <String, String>{
        'limit': '50',
        // Don't filter by locationId if "ALL" is selected or nothing selected
        if (_selectedUnitId != null && _selectedUnitId != 'ALL') 'locationId': _selectedUnitId!,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _api.get<dynamic>('/projects', queryParameters: queryParams);
      if (response.isSuccess && response.data != null) {
        // Handle wrapped response {success, data, meta}
        final rawData = response.data;
        List<dynamic> list;
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map<String, dynamic>) {
          list = rawData['data'] ?? [];
        } else {
          list = [];
        }
        _projects = list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
        debugPrint('PFTCV: Loaded ${_projects.length} projects');
      } else {
        _projects = [];
        debugPrint('PFTCV: No projects returned - ${response.error}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch stats for the selected location
  Future<void> fetchStats() async {
    try {
      final queryParams = <String, String>{
        if (_selectedUnitId != null && _selectedUnitId != 'ALL') 'locationId': _selectedUnitId!,
      };

      final response = await _api.get<dynamic>('/projects/stats', queryParameters: queryParams);
      if (response.isSuccess && response.data != null) {
        // Handle wrapped response {success, data}
        final rawData = response.data;
        if (rawData is Map<String, dynamic>) {
          final statsData = rawData['data'] ?? rawData;
          _stats = PftcvStats.fromJson(statsData as Map<String, dynamic>);
        }
      }
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
