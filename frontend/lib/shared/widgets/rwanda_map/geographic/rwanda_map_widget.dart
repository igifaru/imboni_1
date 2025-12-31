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
class RwandaMapWidget extends StatefulWidget {
  final Map<String, int> casesByDistrict;
  final Function(String) onDistrictSelected;

  const RwandaMapWidget({
    super.key,
    required this.casesByDistrict,
    required this.onDistrictSelected,
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



  @override
  void initState() {
    super.initState();
    _provincesFuture = GeoJsonParser.parseRwandaProvinces();
    _districtsFuture = GeoJsonParser.parseRwandaDistricts();
    _sectorsFuture = GeoJsonParser.parseRwandaSectors();
    _cellsFuture = GeoJsonParser.parseRwandaCells();
    _villagesFuture = GeoJsonParser.parseRwandaVillages();
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
                // Check if loaded (might be processing in isolate)
                final sectors = (snapshot.data != null && snapshot.data!.length > 2) ? (snapshot.data![2] as List<MapRegion>) : <MapRegion>[];
                final cells = (snapshot.data != null && snapshot.data!.length > 3) ? (snapshot.data![3] as List<MapRegion>) : <MapRegion>[];
                final villages = (snapshot.data != null && snapshot.data!.length > 4) ? (snapshot.data![4] as List<MapRegion>) : <MapRegion>[];
                
                if (snapshot.connectionState == ConnectionState.done && villages.isEmpty) {
                   // Optional warning if empty?
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

                // 5. Village Layers (Visible > 13.5) - Lowered threshold
                final villagePolygons = <Polygon>[];
                if (_currentZoom > 13.5) {
                   for (var region in villages) {
                      for (var ring in region.polygons) {
                        villagePolygons.add(
                          Polygon(
                            points: ring,
                            color: Colors.transparent, 
                            borderColor: Colors.greenAccent.withValues(alpha: 0.4),
                            borderStrokeWidth: 0.5,
                            label: region.name,
                            labelStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9, 
                              fontWeight: FontWeight.normal,
                              shadows: [Shadow(blurRadius: 1, color: Colors.black)]
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
                    maxZoom: 18.0, // Increased max zoom for villages
                    onPositionChanged: (pos, hasGesture) {
                       if ((pos.zoom - _currentZoom).abs() > 0.1) {
                         final oldZ = _currentZoom;
                         final newZ = pos.zoom;
                         bool crossedThreshold = (oldZ <= 10.0 && newZ > 10.0) || (oldZ > 10.0 && newZ <= 10.0) ||
                                                 (oldZ <= 12.0 && newZ > 12.0) || (oldZ > 12.0 && newZ <= 12.0) ||
                                                 (oldZ <= 13.5 && newZ > 13.5) || (oldZ > 13.5 && newZ <= 13.5);
                         if (crossedThreshold) {
                           setState(() {
                             _currentZoom = newZ;
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
        ],
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
        children: const [
          Text(
            'National "God View" Dashboard',
            style: TextStyle(
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
           Row(
             children: const [
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
             child: Row(
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
