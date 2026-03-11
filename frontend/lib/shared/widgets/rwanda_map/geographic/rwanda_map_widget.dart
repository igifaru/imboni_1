import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'rwanda_map_painter.dart'; // For RwandaMapData utils if needed
import 'package:imboni/shared/utils/highcharts_parser.dart';

/// Rwanda Map Widget - Real Geographic Map using OpenStreetMap Tiles
/// Features:
/// - Real Tile Layer (Dark Matter)
/// - Accurate Province Polygons (Filled)
/// - Accurate District Polygons (Stroked)
/// - District Name Labels
/// - Data Bubbles (heatmap) at Accurate Centroids
/// - Scope-based zoom and centering (NEW)
class RwandaMapWidget extends StatefulWidget {
  final Map<String, int> casesByDistrict;
  final Function(String) onDistrictSelected;
  final String? mapTitle; // Dynamic title for map header
  
  /// Focus parameters for scope-based centering
  final String? focusProvince;
  final String? focusDistrict;
  final String? focusSector;
  final String? focusCell;
  final String? focusVillage;
  
  /// Whether to allow toggle between focused view and full map
  final bool allowFullMapToggle;

  const RwandaMapWidget({
    super.key,
    required this.casesByDistrict,
    required this.onDistrictSelected,
    this.mapTitle,
    this.focusProvince,
    this.focusDistrict,
    this.focusSector,
    this.focusCell,
    this.focusVillage,
    this.allowFullMapToggle = false,
  });

  @override
  State<RwandaMapWidget> createState() => _RwandaMapWidgetState();
}

class _RwandaMapWidgetState extends State<RwandaMapWidget> {
  late Future<List<MapRegion>> _provincesFuture;
  late Future<List<MapRegion>> _districtsFuture;
  late Future<List<MapRegion>> _sectorsFuture;
  late Future<List<MapRegion>> _cellsFuture;
  late Future<List<MapRegion>> _villagesFuture;
  
  final MapController _mapController = MapController();
  double _currentZoom = 9.0;
  
  /// Whether showing full Rwanda map or focused on user's scope
  bool _isFullMapMode = false;
  
  /// Stores loaded regions for lookups
  List<MapRegion> _loadedProvinces = [];
  List<MapRegion> _loadedDistricts = [];
  List<MapRegion> _loadedSectors = [];
  List<MapRegion> _loadedCells = [];
  List<MapRegion> _loadedVillages = [];
  
  /// Whether the map has been initially centered
  bool _hasInitiallyCentered = false;

  /// Get the deepest focus level and name
  (String level, String name)? get _focusTarget {
    if (widget.focusVillage != null) return ('village', widget.focusVillage!);
    if (widget.focusCell != null) return ('cell', widget.focusCell!);
    if (widget.focusSector != null) return ('sector', widget.focusSector!);
    if (widget.focusDistrict != null) return ('district', widget.focusDistrict!);
    if (widget.focusProvince != null) return ('province', widget.focusProvince!);
    return null;
  }

  /// Get appropriate zoom level for each administrative level
  double _getZoomForLevel(String level) {
    switch (level) {
      case 'province': return 10.0;
      case 'district': return 11.0;
      case 'sector': return 12.5;
      case 'cell': return 14.5;
      case 'village': return 16.5; // Deeper zoom for "real visible" accuracy
      default: return 9.2;
    }
  }

  @override
  void initState() {
    super.initState();
    _provincesFuture = GeoJsonParser.parseRwandaProvinces();
    _districtsFuture = GeoJsonParser.parseRwandaDistricts();
    // Optimization: Don't parse deep layers in general dashboard view unless zoomed
    _sectorsFuture = Future.value(<MapRegion>[]);
    _cellsFuture = Future.value(<MapRegion>[]);
    _villagesFuture = Future.value(<MapRegion>[]);
  }

  @override
  void didUpdateWidget(covariant RwandaMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if focus parameters changed
    final focusChanged = 
        widget.focusProvince != oldWidget.focusProvince ||
        widget.focusDistrict != oldWidget.focusDistrict ||
        widget.focusSector != oldWidget.focusSector ||
        widget.focusCell != oldWidget.focusCell ||
        widget.focusVillage != oldWidget.focusVillage;
        
    // Check if map mode or toggle ability changed
    if (widget.allowFullMapToggle != oldWidget.allowFullMapToggle) {
       // Reset if capability changes
       if (!widget.allowFullMapToggle) {
         _isFullMapMode = false;
       }
    }

    // Trigger re-centering if focus changed and we're not in full map mode
    if (focusChanged) {
      debugPrint('MAP: Focus parameters updated. Centering on $_focusTarget');
      // Force re-centering even if user moved map (for initial dashboard load experience)
      if (!_isFullMapMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _centerOnFocusRegion();
        });
      }
    }
  }

  /// Find a region by name with robust matching and optional parent context
  MapRegion? _findRegion(String level, String name, {String? parentName}) {
    if (name.isEmpty) return null;
    final normalizedTarget = name.toLowerCase().trim()
        .replaceAll(' iii', ' 3')
        .replaceAll(' ii', ' 2')
        .replaceAll(' i', ' 1'); // Normalize numerals
    
    // Cleanup parent name if provided
    final normalizedParent = parentName?.toLowerCase().trim();
    
    List<MapRegion> regions;
    switch (level) {
      case 'province': regions = _loadedProvinces; break;
      case 'district': regions = _loadedDistricts; break;
      case 'sector': regions = _loadedSectors; break;
      case 'cell': regions = _loadedCells; break;
      case 'village': regions = _loadedVillages; break;
      default: return null;
    }
    
    // Filter candidates by parent context FIRST if available
    var candidates = regions;
    if (normalizedParent != null) {
      debugPrint('MAP FILTER: Filtering ${regions.length} regions by parent "$normalizedParent"');
      
      // Filter/Score candidates
      // Strategy: 
      // 1. Text Filter (Parent Name) - if metadata exists
      // 2. Proximity Score (Parent Centroid) - if parent metadata is missing but Parent Region is loaded
      
      MapRegion? parentRegion;
      
      // Attempt to find parent region object for spatial context
      if (parentName != null) {
          String? pLevel;
          // Determine parent level
          if (level == 'village') { pLevel = 'cell'; }
          else if (level == 'cell') { pLevel = 'sector'; }
          else if (level == 'sector') { pLevel = 'district'; }
          else if (level == 'district') { pLevel = 'province'; }
          
          if (pLevel != null) {
             // Recursive lookup for parent (without parent context to avoid infinite loop)
             parentRegion = _findRegion(pLevel, parentName);
          }
      }

      // Very strict parent matching: candidate.parentName must contain/be contained by normalizedParent
      final filtered = regions.where((r) {
         if (r.parentName == null) return true; // Keep if no parent info (don't discard yet)
         final pName = r.parentName!.toLowerCase().trim();
         return pName.contains(normalizedParent) || normalizedParent.contains(pName);
      }).toList();
      
      // Sort to prioritize:
      // 1. Explicit Parent Name Match
      // 2. Proximity to Parent Centroid (if Parent Region found)
      filtered.sort((a, b) {
         // Score A
         bool aNameMatch = a.parentName != null && (a.parentName!.toLowerCase().contains(normalizedParent) || normalizedParent.contains(a.parentName!.toLowerCase()));
         double aDist = double.maxFinite;
         if (parentRegion != null) {
            // Calculate distanceDeg (simple Euclidean is enough for sorting logic on small scale)
            double dx = a.centroid.longitude - parentRegion.centroid.longitude;
            double dy = a.centroid.latitude - parentRegion.centroid.latitude;
            aDist = dx*dx + dy*dy;
         }

         // Score B
         bool bNameMatch = b.parentName != null && (b.parentName!.toLowerCase().contains(normalizedParent) || normalizedParent.contains(b.parentName!.toLowerCase()));
         double bDist = double.maxFinite;
         if (parentRegion != null) {
            double dx = b.centroid.longitude - parentRegion.centroid.longitude;
            double dy = b.centroid.latitude - parentRegion.centroid.latitude;
            bDist = dx*dx + dy*dy;
         }
         
         // 1. Name Match Wins
         if (aNameMatch && !bNameMatch) return -1;
         if (!aNameMatch && bNameMatch) return 1;
         
         // 2. If both (or neither) match name, use Proximity
         if (parentRegion != null) {
            return aDist.compareTo(bDist);
         }
         
         return 0;
      });
      
      // Only apply filter if it doesn't eliminate everyone (safety fallback)
      if (filtered.isNotEmpty) {
        if (parentRegion != null) {
           debugPrint('MAP CONTEXT: Using Spatial Context from parent "${parentRegion.name}"');
        }
        debugPrint('MAP FILTER SUCCESS: Reduced to ${filtered.length} candidates (Matched parent/proximity)');
        candidates = filtered;
      }
    }
    
    // Debug region loading
    if (regions.isEmpty) {
       debugPrint('MAP DEBUG: No loaded regions for level $level.');
    } 

    // Pass 1: EXACT MATCH (Highest Priority)
    for (var region in candidates) {
      if (region.name.toLowerCase().trim() == name.toLowerCase().trim()) {
        return region;
      }
    }
    
    // Pass 2: NORMALIZED EXACT MATCH (Handle III vs 3)
    for (var region in candidates) {
      final normalizedRegion = region.name.toLowerCase().trim()
          .replaceAll(' iii', ' 3')
          .replaceAll(' ii', ' 2')
          .replaceAll(' i', ' 1');
      if (normalizedRegion == normalizedTarget) {
        return region;
      }
    }

    // Pass 3: TOKEN-BASED FUZZY MATCH (Robust)
    final targetTokens = normalizedTarget.split(' ').where((t) => t.isNotEmpty).toSet();
    MapRegion? bestTokenCandidate;
    int maxIntersect = 0;
    
    for (var region in candidates) {
      final rName = region.name.toLowerCase().trim()
          .replaceAll(' iii', ' 3')
          .replaceAll(' ii', ' 2')
          .replaceAll(' i', ' 1');
          
      final rTokens = rName.split(' ').where((t) => t.isNotEmpty).toSet();
      final intersection = targetTokens.intersection(rTokens).length;
      
      if (intersection > maxIntersect) {
        maxIntersect = intersection;
        bestTokenCandidate = region;
      }
    }
    
    if (bestTokenCandidate != null && maxIntersect > 0) {
       // Only accept token match if intersection is significant
       if (maxIntersect >= 1) { 
          debugPrint('MAP MATCH: Found token match for "$name" -> "${bestTokenCandidate.name}" (Intersection: $maxIntersect)');
          return bestTokenCandidate;
       }
    }

    // Debug failure to find
    if (level == 'village' || level == 'cell') {
       debugPrint('MAP MATCH FAIL: Could not find "$name" in $level regions (Total Candidates: ${candidates.length}). Parent Context: $parentName');
    }
    
    return null;
  }

  /// Center map on the focus region with fallback
  void _centerOnFocusRegion() {
    if (_isFullMapMode) {
      _centerOnFullMap();
      return;
    }
    
    // Try to find region, falling back to parents if not found
    MapRegion? region;
    String? level;
    String? name;
    
    // 1. Try Village (Context: Cell)
    if (widget.focusVillage != null) {
       level = 'village';
       name = widget.focusVillage!;
       region = _findRegion(level, name, parentName: widget.focusCell);
    }
    
    // 2. Try Cell (Fallback) (Context: Sector)
    if (region == null && widget.focusCell != null) {
       level = 'cell';
       name = widget.focusCell!;
       region = _findRegion(level, name, parentName: widget.focusSector);
    }
    
    // 3. Try Sector (Fallback) (Context: District)
    if (region == null && widget.focusSector != null) {
       level = 'sector';
       name = widget.focusSector!;
       region = _findRegion(level, name, parentName: widget.focusDistrict);
    }
    
    // 4. Try District (Fallback) (Context: Province)
    if (region == null && widget.focusDistrict != null) {
       level = 'district';
       name = widget.focusDistrict!;
       region = _findRegion(level, name, parentName: widget.focusProvince);
    }
    
    if (region != null && level != null) {
      final zoom = _getZoomForLevel(level);
      _mapController.move(region.centroid, zoom);
      _currentZoom = zoom;
    } else {
       // If absolutely nothing found, center on default
       _centerOnFullMap();
       debugPrint('MAP ERROR: Could not find any focus target in hierarchy.');
    }
  }

  void _centerOnFullMap() {
    _mapController.move(const LatLng(-1.9403, 30.05), 9.2);
    _currentZoom = 9.2;
  }

  /// Toggle between full map and focused view
  void _toggleFullMapMode() {
    setState(() {
      _isFullMapMode = !_isFullMapMode;
    });
    _centerOnFocusRegion();
  }

  // Colors matching the reference map style (Official / Figma)
  Color _getProvinceColor(String id) {

    switch (id) {
      case 'RW.K': return Colors.pinkAccent.withValues(alpha: 0.4);
      case 'RW.N': return Colors.amber.withValues(alpha: 0.4);
      case 'RW.S': return Colors.orangeAccent.withValues(alpha: 0.4);
      case 'RW.E': return const Color(0xFFD2B48C).withValues(alpha: 0.4); // Tan
      case 'RW.W': return Colors.lightGreen.withValues(alpha: 0.4);
      default: return Colors.grey.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Confirm data arrival
    if (widget.focusVillage != null) {
      debugPrint('MAP BUILD: FocusVillage = "${widget.focusVillage}"');
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([_provincesFuture, _districtsFuture, _sectorsFuture, _cellsFuture, _villagesFuture]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                   debugPrint('MAP LOAD ERROR: ${snapshot.error}');
                }
                
                final provinces = (snapshot.data != null && snapshot.data!.isNotEmpty) ? (snapshot.data![0] as List<MapRegion>) : <MapRegion>[];
                final districts = (snapshot.data != null && snapshot.data!.length > 1) ? (snapshot.data![1] as List<MapRegion>) : <MapRegion>[];
                final sectors = (snapshot.data != null && snapshot.data!.length > 2) ? (snapshot.data![2] as List<MapRegion>) : <MapRegion>[];
                final cells = (snapshot.data != null && snapshot.data!.length > 3) ? (snapshot.data![3] as List<MapRegion>) : <MapRegion>[];
                final villages = (snapshot.data != null && snapshot.data!.length > 4) ? (snapshot.data![4] as List<MapRegion>) : <MapRegion>[];
                
                // Store loaded regions for lookup methods
                if (snapshot.connectionState == ConnectionState.done && !_hasInitiallyCentered) {
                  _loadedProvinces = provinces;
                  _loadedDistricts = districts;
                  _loadedSectors = sectors;
                  _loadedCells = cells;
                  _loadedVillages = villages;
                  
                  // Trigger initial centering after frame renders
                  if (_focusTarget != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_hasInitiallyCentered) {
                        _hasInitiallyCentered = true;
                        _centerOnFocusRegion();
                      }
                    });
                  }
                }

                // LAYERS VISIBILITY LOGIC
                // 1. Province Layers (Always visible as base color)
                final provincePolygons = <Polygon>[];
                for (var region in provinces) {
                    for (var ring in region.polygons) {
                       provincePolygons.add(
                        Polygon(
                           points: ring,
                           color: _getProvinceColor(region.id),
                           borderColor: Colors.white.withValues(alpha: 0.2),
                           borderStrokeWidth: 2.0,
                         ),
                       );
                    }
                }

                // 2. District Layers (Visible < 12.0) - Outline only
                final districtPolygons = <Polygon>[];
                // Hide districts when zoomed deep to reduce clutter
                if (_currentZoom < 12.0) {
                  for (var region in districts) {
                      for (var ring in region.polygons) {
                        districtPolygons.add(
                          Polygon(
                            points: ring,
                            color: Colors.transparent, 
                            borderColor: Colors.white.withValues(alpha: 0.5),
                            borderStrokeWidth: 1.0,
                            label: region.name,
                          ),
                        );
                      }
                  }
                }

                // 3. Sector Layers (Visible > 10.0)
                final sectorPolygons = <Polygon>[];
                if (_currentZoom > 10.0) {
                   for (var region in sectors) {
                      for (var ring in region.polygons) {
                        sectorPolygons.add(
                          Polygon(
                            points: ring,
                            color: Colors.transparent, // Or slight fill?
                            borderColor: Colors.cyanAccent.withValues(alpha: 0.5),
                            borderStrokeWidth: 1.2, // Thicker for visibility
                            label: region.name,
                          ),
                        );
                      }
                   }
                }

                // 4. Cell Layers (Visible > 12.0)
                final cellPolygons = <Polygon>[];
                if (_currentZoom > 12.0) {
                   for (var region in cells) {
                      for (var ring in region.polygons) {
                        cellPolygons.add(
                          Polygon(
                            points: ring,
                            color: Colors.transparent, 
                            borderColor: Colors.yellowAccent.withValues(alpha: 0.4),
                            borderStrokeWidth: 0.8,
                            label: region.name,
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 10, 
                              fontWeight: FontWeight.w500,
                              shadows: [Shadow(blurRadius: 1, color: Colors.black)]
                            ),
                          ),
                        );
                      }
                   }
                }

                // 5. Village Layers (Visible > 13.0) - More aggressive visibility
                final villagePolygons = <Polygon>[];
                if (_currentZoom > 13.0) {
                   for (var region in villages) {
                      for (var ring in region.polygons) {
                        villagePolygons.add(
                          Polygon(
                            points: ring,
                            color: Colors.greenAccent.withValues(alpha: 0.1), // Real visible fill
                            borderColor: Colors.greenAccent.withValues(alpha: 0.5),
                            borderStrokeWidth: 1.0, // Thicker border
                            label: region.name,
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11, // Larger font
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(blurRadius: 2, color: Colors.black)]
                            ),
                          ),
                        );
                      }
                   }
                }

                // 6. District Labels & Data Bubbles (Check valid for zoom)
                final markers = <Marker>[];
                // Only show district bubbles if zoomed out? Or always?
                if (_currentZoom < 13.0) {
                  for (var region in districts) {
                     final name = region.name;
                     // final count = widget.casesByDistrict[name] ?? 0;
                     final countUpper = widget.casesByDistrict[name.toUpperCase()] ?? 
                                        widget.casesByDistrict[name] ?? 0;

                     markers.add(
                          Marker(
                            point: region.centroid,
                            width: 100,
                            height: 30,
                            alignment: Alignment.topCenter, 
                            child: Transform.translate(
                              offset: const Offset(0, 20),
                              child: Text(
                                name.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  shadows: const [
                                    Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1,1))
                                  ]
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                     );

                     if (countUpper > 0 || true) {
                        final bubbleSize = RwandaMapData.getBubbleSize(countUpper);
                        final bubbleColor = RwandaMapData.getBubbleColor(countUpper);
                        
                        markers.add(
                          Marker(
                            point: region.centroid,
                            width: bubbleSize * 2.5,
                            height: bubbleSize * 2.5,
                            child: GestureDetector(
                              onTap: () => widget.onDistrictSelected(name),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bubbleColor.withValues(alpha: 0.6),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: bubbleColor.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                ),
                              ),
                            ),
                          )
                        );
                     }
                  }
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-1.9403, 30.05),
                    initialZoom: 9.2,
                    minZoom: 8.0,
                    maxZoom: 19.0, // Allow deeper zoom for field level accuracy
                    onPositionChanged: (pos, hasGesture) {
                       if ((pos.zoom - _currentZoom).abs() > 0.1) {
                         final oldZ = _currentZoom;
                         final newZ = pos.zoom;
                         bool crossedThreshold = (oldZ <= 10.0 && newZ > 10.0) || (oldZ > 10.0 && newZ <= 10.0) ||
                                                 (oldZ <= 12.0 && newZ > 12.0) || (oldZ > 12.0 && newZ <= 12.0) ||
                                                 (oldZ <= 13.5 && newZ > 13.5) || (oldZ > 13.5 && newZ <= 13.5);
                         if (crossedThreshold) {
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                             if (mounted) setState(() { _currentZoom = newZ; });
                           });
                         } else {
                           _currentZoom = newZ;
                         }
                       }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.imboni.app',
                    ),
                    PolygonLayer(polygons: provincePolygons),
                    if (_currentZoom > 10.5) PolygonLayer(polygons: sectorPolygons),
                    if (_currentZoom > 12.5) PolygonLayer(polygons: cellPolygons),
                    if (_currentZoom > 14.5) PolygonLayer(polygons: villagePolygons),
                    if (_currentZoom < 13.0) PolygonLayer(polygons: districtPolygons),
                    MarkerLayer(markers: markers),
                  ],
                );
              },
            ),
          ),
          
          // Header (Floating)
          Positioned(
            top: 16,
            left: 16,
            child: _buildHeader(isDark),
          ),

          // AI Insights Panel (Floating Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: _buildAIInsights(isDark),
          ),

          // Legend (Floating Bottom Right)
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildLegend(isDark),
          ),
          
          // Full Map Toggle Button (Floating Bottom Left) - Only if allowed and has focus
          if (widget.allowFullMapToggle && _focusTarget != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildFullMapToggle(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildFullMapToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggleFullMapMode,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFullMapMode ? Icons.my_location : Icons.public,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isFullMapMode ? 'My Location' : 'View Full Map',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.mapTitle ?? 'National "God View" Dashboard',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights(bool isDark) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A38).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
           const Row(
             children: [
               Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 16),
               SizedBox(width: 8),
               Text('AI Insights', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
             ],
           ),
           const SizedBox(height: 8),
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.orange.withValues(alpha: 0.2),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
             ),
             child: const Row(
               children: [
                 Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                 SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     'Increase in land disputes in North Province',
                     style: TextStyle(color: Colors.orange, fontSize: 12),
                   ),
                 ),
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Issue Density', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendItem(Colors.green, 'Low'),
              const SizedBox(width: 8),
              _legendItem(Colors.amber, 'Med'),
              const SizedBox(width: 8),
              _legendItem(Colors.red, 'High'),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 4),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
