import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class MapRegion {
  final String id;
  final String name;
  final String? parentName; // Added for disambiguation
  final List<List<LatLng>> polygons;
  final LatLng centroid;

  MapRegion({
    required this.id,
    required this.name,
    this.parentName,
    required this.polygons,
    required this.centroid,
  });
}

class GeoJsonParser {
  /// Parses standard GeoJSON (geoBoundaries) for Rwanda Provinces
  static Future<List<MapRegion>> parseRwandaProvinces() async {
    return parse('assets/rwanda_adm1.geojson', isProvince: true);
  }

  /// Parses standard GeoJSON for Rwanda Districts (ADM2)
  static Future<List<MapRegion>> parseRwandaDistricts() async {
    return parse('assets/rwanda_adm2.geojson', isProvince: false, parentKeys: ['ADM1_EN', 'ADM1_RW', 'Province', 'PROVINCE']);
  }
  
  /// Parses standard GeoJSON for Rwanda Sectors (ADM3)
  static Future<List<MapRegion>> parseRwandaSectors() async {
    return parse('assets/rwanda_adm3.geojson', parentKeys: ['ADM2_EN', 'ADM2_RW', 'District', 'DISTRICT']);
  }

  /// Parses standard GeoJSON for Rwanda Cells (ADM4)
  static Future<List<MapRegion>> parseRwandaCells() async {
    return parse('assets/rwanda_adm4.geojson', parentKeys: ['ADM3_EN', 'ADM3_RW', 'Sector', 'SECTOR']);
  }

  /// Parses standard GeoJSON for Rwanda Villages (ADM5)
  static Future<List<MapRegion>> parseRwandaVillages() async {
     // ADM5 is huge (130MB+), use isolate.
    return parse('assets/rwanda_adm5.geojson', parentKeys: ['ADM4_EN', 'ADM4_RW', 'Cell', 'CELL']);
  }

  
  // Correct Pattern: Load bytes in main, decode & parse in isolate to save memory
  static Future<List<MapRegion>> parse(String assetPath, {bool isProvince = false, List<String>? parentKeys}) async {
    try {
      // Use load instead of loadString to avoid UTF-16 expansion on main thread
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Transfer bytes to isolate
      return compute(_parseGeoJSONBytes, {'bytes': bytes, 'isProvince': isProvince, 'parentKeys': parentKeys});
    } catch (e) {
      debugPrint('Error loading $assetPath: $e');
      return [];
    }
  }

  static List<MapRegion> _parseGeoJSONBytes(Map<String, dynamic> params) {
    try {
      final Uint8List bytes = params['bytes'] as Uint8List;
      final bool isProvince = params['isProvince'] as bool;
      final List<String>? parentKeys = params['parentKeys'] as List<String>?;
      
      // Decode UTF-8 in isolate
      final String jsonString = utf8.decode(bytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      final features = data['features'] as List;
      final List<MapRegion> regions = [];

      for (var f in features) {
        final props = f['properties'] as Map<String, dynamic>;
        
        // DEBUG: Print keys for the first item to debug parent extraction
        if (regions.isEmpty && features.indexOf(f) == 0) {
           // print is more reliable than debugPrint in isolates for some envs
           print('GEOJSON DEBUG ($isProvince): Keys available -> ${props.keys.toList()}'); 
           if (parentKeys != null) {
              print('GEOJSON DEBUG: Looking for any of parentKeys $parentKeys');
           }
        }
        
        String rawName = props['shapeName'] ?? 
                         props['ADM5_EN'] ?? 
                         props['ADM5_RW'] ??
                         props['ADM4_EN'] ?? 
                         props['ADM3_EN'] ?? 
                         props['ADM2_EN'] ?? 
                         props['ADM1_EN'] ?? 
                         props['Name'] ?? 
                         props['NAME'] ?? 
                         props['VILLAGE'] ??
                         props['CELL'] ??
                         props['SECTOR'] ??
                         props['DISTRICT'] ??
                         props['PROVINCE'] ??
                         '';
                         
        // Parse Parent Name for disambiguation using specific keys if available
        String? parentName;
        if (parentKeys != null) {
          for (var key in parentKeys) {
            if (props[key] != null) {
              parentName = props[key];
              break;
            }
          }
        } 
        
        if (parentName == null) {
           // Fallback chain (legacy)
           parentName = props['ADM4_EN'] ?? 
                        props['ADM3_EN'] ?? 
                        props['ADM2_EN'] ?? 
                        props['ADM1_EN'] ??
                        props['Parent']; // Generic fallback
        }
                             
        // Cleanup name (remove type suffixes if present)
        // rawName = rawName.replaceAll(RegExp(r'\s+(Village|Cell|Sector|District|Province)$', caseSensitive: false), '');

        String id = rawName;
        // Colors mapping logic for provinces
        if (isProvince) {
             if (rawName.contains('Kigali')) {
               id = 'RW.K';
             } else if (rawName.contains('North')) {
               id = 'RW.N';
             } else if (rawName.contains('South')) {
               id = 'RW.S';
             } else if (rawName.contains('East')) {
               id = 'RW.E';
             } else if (rawName.contains('West')) {
               id = 'RW.W';
             }
        }

        final geometry = f['geometry'];
        if (geometry == null) continue;

        final type = geometry['type'];
        final coords = geometry['coordinates'] as List;
        
        final List<List<LatLng>> polygons = [];

        if (type == 'Polygon') {
          for (var ring in coords) {
            polygons.add(_parseRing(ring as List));
          }
        } else if (type == 'MultiPolygon') {
          for (var polygon in coords) {
             for (var ring in (polygon as List)) {
               polygons.add(_parseRing(ring as List));
             }
          }
        }

        if (polygons.isNotEmpty) {
           regions.add(MapRegion(
             id: id,
             name: rawName,
             parentName: parentName,
             polygons: polygons,
             centroid: _computeCentroid(polygons),
           ));
        }
      }
      return regions;
    } catch (e) {
      debugPrint('Error parsing GeoJSON in isolate: $e');
      return [];
    }
  }

  static LatLng _computeCentroid(List<List<LatLng>> polygons) {
     // Simple average of all points in the first ring of the first polygon (usually the main one)
     // Or average of bounding box?
     // Better: Average of all points.
     double sumLat = 0;
     double sumLon = 0;
     int count = 0;
     
     // Find largest polygon to avoid tiny islands skewing center
     List<LatLng> mainRing = polygons[0];
     int maxLength = 0;
     for (var p in polygons) {
       if (p.length > maxLength) {
         maxLength = p.length;
         mainRing = p;
       }
     }

     for (var p in mainRing) {
       sumLat += p.latitude;
       sumLon += p.longitude;
       count++;
     }
     
     return LatLng(sumLat / count, sumLon / count);
  }

  static List<LatLng> _parseRing(List<dynamic> ring) {
    return ring.map((point) {
      final p = point as List;
      // GeoJSON is [Lon, Lat]
      return LatLng(p[1].toDouble(), p[0].toDouble());
    }).toList();
  }
}
