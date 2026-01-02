import 'package:flutter/foundation.dart';
import '../models/location_selection.dart';
import '../../../services/api_client.dart';

/// Controller for managing scoped map views based on user role and assignment.
/// 
/// For Leaders: Restricts navigation to their assigned administrative unit and below.
/// For Citizens: Shows their registered location with option to view full map.
class ScopedMapController extends ChangeNotifier {
  LocationSelection _selection = const LocationSelection();
  AdministrativeLevel _userScopeLevel = AdministrativeLevel.none;
  bool _isFullMapMode = false;
  bool _isLoading = true;
  String? _error;

  // User scope data from backend
  String? _scopeProvince;
  String? _scopeDistrict;
  String? _scopeSector;
  String? _scopeCell;
  String? _scopeVillage;
  String? _userRole;

  LocationSelection get selection => _selection;
  AdministrativeLevel get userScopeLevel => _userScopeLevel;
  bool get isFullMapMode => _isFullMapMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userRole => _userRole;

  /// Whether the user can toggle to full map view (Citizens only)
  bool get canViewFullMap => _userRole == 'CITIZEN';

  /// Whether the user can drill up from current level
  bool get canDrillUp {
    if (_isFullMapMode) return true; // Full map = no restrictions
    return _selection.canDrillUp(_userScopeLevel);
  }

  /// Initialize controller by fetching user's scope from backend
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/my-jurisdiction');
      
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _parseUserScope(data);
        _initializeSelection();
      } else {
        _error = response.error ?? 'Failed to load user scope';
      }
    } catch (e) {
      _error = 'Error loading scope: $e';
      debugPrint(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  void _parseUserScope(Map<String, dynamic> data) {
    _userRole = data['role'] as String?;
    
    final unit = data['unit'] as Map<String, dynamic>?;
    if (unit != null) {
      final level = unit['level'] as String?;
      final path = data['path'] as List<dynamic>?;
      
      // Parse the hierarchy path
      if (path != null) {
        for (final item in path) {
          final itemMap = item as Map<String, dynamic>;
          final itemLevel = itemMap['level'] as String?;
          final itemName = itemMap['name'] as String?;
          
          switch (itemLevel) {
            case 'PROVINCE':
              _scopeProvince = itemName;
              break;
            case 'DISTRICT':
              _scopeDistrict = itemName;
              break;
            case 'SECTOR':
              _scopeSector = itemName;
              break;
            case 'CELL':
              _scopeCell = itemName;
              break;
            case 'VILLAGE':
              _scopeVillage = itemName;
              break;
          }
        }
      }
      
      // Determine scope level
      _userScopeLevel = _parseLevel(level);
    }
  }

  AdministrativeLevel _parseLevel(String? level) {
    switch (level?.toUpperCase()) {
      case 'PROVINCE':
        return AdministrativeLevel.province;
      case 'DISTRICT':
        return AdministrativeLevel.district;
      case 'SECTOR':
        return AdministrativeLevel.sector;
      case 'CELL':
        return AdministrativeLevel.cell;
      case 'VILLAGE':
        return AdministrativeLevel.village;
      default:
        return AdministrativeLevel.none;
    }
  }

  void _initializeSelection() {
    // Set initial selection based on user's scope
    _selection = LocationSelection.fromScope(
      province: _scopeProvince,
      district: _scopeDistrict,
      sector: _scopeSector,
      cell: _scopeCell,
      village: _scopeVillage,
      scopeLevel: _userScopeLevel,
    );
  }

  /// Update selection when user navigates the map
  void updateSelection(LocationSelection newSelection) {
    // Enforce scope limits for leaders
    if (!_isFullMapMode && _userRole != 'CITIZEN') {
      // Can't drill up beyond scope
      if (!newSelection.canDrillUp(_userScopeLevel)) {
        return; // Ignore navigation attempts above scope
      }
    }
    
    _selection = newSelection;
    notifyListeners();
  }

  /// Toggle between scoped view and full Rwanda map (Citizens only)
  void toggleFullMapMode() {
    if (!canViewFullMap) return;
    
    _isFullMapMode = !_isFullMapMode;
    
    if (_isFullMapMode) {
      // Show full map starting from provinces
      _selection = const LocationSelection();
    } else {
      // Return to user's scoped view
      _initializeSelection();
    }
    
    notifyListeners();
  }

  /// Navigate back one level
  void goBack() {
    switch (_selection.currentLevel) {
      case AdministrativeLevel.village:
        _selection = _selection.copyWith(village: null);
        break;
      case AdministrativeLevel.cell:
        _selection = _selection.copyWith(cell: null);
        break;
      case AdministrativeLevel.sector:
        _selection = _selection.copyWith(sector: null);
        break;
      case AdministrativeLevel.district:
        _selection = _selection.copyWith(district: null);
        break;
      case AdministrativeLevel.province:
        if (_isFullMapMode || _userScopeLevel == AdministrativeLevel.none) {
          _selection = const LocationSelection();
        }
        break;
      case AdministrativeLevel.none:
        break;
    }
    notifyListeners();
  }

  /// Reset to user's default scope
  void resetToScope() {
    _isFullMapMode = false;
    _initializeSelection();
    notifyListeners();
  }
}

/// Global instance
final scopedMapController = ScopedMapController();
