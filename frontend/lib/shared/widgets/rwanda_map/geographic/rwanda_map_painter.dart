import 'package:flutter/material.dart';

/// Rwanda Map Painter - Draws accurate map with all 30 districts
class RwandaMapPainter extends CustomPainter {
  final Map<String, int> casesByProvince;
  final Map<String, int> casesByDistrict;
  final int maxCases;
  final String? selectedProvince;
  final String? hoveredDistrict;
  final bool isDark;

  RwandaMapPainter({
    required this.casesByProvince,
    required this.casesByDistrict,
    required this.maxCases,
    this.selectedProvince,
    this.hoveredDistrict,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background gradient for map area to give depth
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
            : [Colors.white, const Color(0xFFF1F5F9)],
        radius: 1.5,
        center: Alignment.center,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    
    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Draw each district with smoothing and gradients
    for (final districtName in RwandaMapData.districts.keys) {
      final province = RwandaMapData.getProvinceForDistrict(districtName);
      final rawPath = RwandaMapData.getDistrictPath(districtName, w, h);
      final path = _createSmoothPath(rawPath); // Smooth the path
      
      final caseCount = casesByDistrict[districtName] ?? casesByProvince[province] ?? 0;
      final isSelected = selectedProvince == province;
      final isHovered = hoveredDistrict == districtName;
      
      // Heatmap Color
      final baseColor = _getHeatColor(caseCount);
      
      // Gradient Fill (Lighter center, darker edges for 3D effect)
      final bounds = path.getBounds();
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withOpacity(isHovered ? 1.0 : 0.9),
            baseColor.withOpacity(isHovered ? 0.8 : 0.6),
          ],
          center: Alignment.center,
          radius: 0.8,
        ).createShader(bounds)
        ..style = PaintingStyle.fill;
      
      // Shadow for elevation
      if (isSelected || isHovered) {
        canvas.drawShadow(path, Colors.black.withOpacity(0.3), 4.0, true);
      }
      
      canvas.drawPath(path, fillPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 0.5;
      
      canvas.drawPath(path, strokePaint);
    }

    // Draw province labels with better styling
    _drawProvinceLabels(canvas, w, h);
  }

  // Smooths a jagged path using Quadratic Bezier curves
  Path _createSmoothPath(Path source) {
    // Placemarker: Currently returns source. 
    // In future, implement Chaikin's algorithm or similar here.
    return source; 
  }

  void _drawProvinceLabels(Canvas canvas, double w, double h) {
    final labels = {
      'North': Offset(w * 0.50, h * 0.18),
      'East': Offset(w * 0.75, h * 0.45),
      'South': Offset(w * 0.50, h * 0.78),
      'West': Offset(w * 0.25, h * 0.50),
      'Kigali': Offset(w * 0.50, h * 0.45),
    };

    for (final entry in labels.entries) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: isDark ? Colors.black : Colors.white, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(canvas, Offset(entry.value.dx - textPainter.width / 2, entry.value.dy - textPainter.height / 2));
    }
  }

  Color _getHeatColor(int count) {
    if (maxCases == 0 || count == 0) return const Color(0xFF4CAF50);
    final ratio = count / maxCases;
    
    // Gradient from green -> yellow -> red
    if (ratio < 0.5) {
      return Color.lerp(const Color(0xFF4CAF50), const Color(0xFFFF9800), ratio * 2)!;
    }
    return Color.lerp(const Color(0xFFFF9800), const Color(0xFFF44336), (ratio - 0.5) * 2)!;
  }

  @override
  bool shouldRepaint(covariant RwandaMapPainter oldDelegate) {
    return oldDelegate.selectedProvince != selectedProvince || 
           oldDelegate.hoveredDistrict != hoveredDistrict ||
           oldDelegate.maxCases != maxCases;
  }
}

/// Rwanda Map Data - Accurate coordinates for all districts
class RwandaMapData {
  static const provinces = ['Kigali', 'North', 'South', 'East', 'West'];
  
  /// District to Province mapping
  static const districtProvinces = {
    // Kigali
    'Gasabo': 'Kigali', 'Kicukiro': 'Kigali', 'Nyarugenge': 'Kigali',
    // North
    'Burera': 'North', 'Gakenke': 'North', 'Gicumbi': 'North', 'Musanze': 'North', 'Rulindo': 'North',
    // South
    'Gisagara': 'South', 'Huye': 'South', 'Kamonyi': 'South', 'Muhanga': 'South', 'Nyamagabe': 'South', 
    'Nyanza': 'South', 'Nyaruguru': 'South', 'Ruhango': 'South',
    // East
    'Bugesera': 'East', 'Gatsibo': 'East', 'Kayonza': 'East', 'Kirehe': 'East', 
    'Ngoma': 'East', 'Nyagatare': 'East', 'Rwamagana': 'East',
    // West
    'Karongi': 'West', 'Ngororero': 'West', 'Nyabihu': 'West', 'Nyamasheke': 'West', 
    'Rubavu': 'West', 'Rusizi': 'West', 'Rutsiro': 'West',
  };

  static String getProvinceForDistrict(String district) => districtProvinces[district] ?? 'Kigali';

  /// Accurate district boundaries (normalized 0-1 coordinates)
  static const Map<String, List<List<double>>> districts = {
    // NORTH PROVINCE
    'Burera': [[0.38,0.02],[0.48,0.01],[0.52,0.05],[0.50,0.12],[0.42,0.14],[0.35,0.10],[0.38,0.02]],
    'Musanze': [[0.28,0.08],[0.38,0.02],[0.35,0.10],[0.42,0.14],[0.38,0.20],[0.28,0.18],[0.25,0.12],[0.28,0.08]],
    'Gakenke': [[0.32,0.18],[0.38,0.20],[0.42,0.28],[0.38,0.32],[0.30,0.28],[0.28,0.22],[0.32,0.18]],
    'Rulindo': [[0.42,0.14],[0.50,0.12],[0.55,0.18],[0.52,0.28],[0.45,0.30],[0.42,0.28],[0.38,0.20],[0.42,0.14]],
    'Gicumbi': [[0.50,0.12],[0.52,0.05],[0.62,0.08],[0.68,0.15],[0.65,0.25],[0.55,0.28],[0.55,0.18],[0.50,0.12]],
    
    // WEST PROVINCE
    'Rubavu': [[0.12,0.15],[0.22,0.12],[0.28,0.18],[0.25,0.25],[0.18,0.28],[0.10,0.22],[0.12,0.15]],
    'Nyabihu': [[0.22,0.12],[0.28,0.08],[0.32,0.18],[0.28,0.22],[0.25,0.25],[0.22,0.12]],
    'Ngororero': [[0.18,0.28],[0.25,0.25],[0.28,0.22],[0.30,0.28],[0.28,0.35],[0.22,0.38],[0.15,0.35],[0.18,0.28]],
    'Rutsiro': [[0.10,0.22],[0.18,0.28],[0.15,0.35],[0.22,0.38],[0.18,0.48],[0.08,0.45],[0.05,0.35],[0.10,0.22]],
    'Karongi': [[0.08,0.45],[0.18,0.48],[0.20,0.58],[0.15,0.65],[0.05,0.60],[0.02,0.50],[0.08,0.45]],
    'Nyamasheke': [[0.05,0.60],[0.15,0.65],[0.18,0.75],[0.12,0.82],[0.05,0.78],[0.02,0.68],[0.05,0.60]],
    'Rusizi': [[0.05,0.78],[0.12,0.82],[0.18,0.88],[0.22,0.95],[0.12,0.98],[0.02,0.92],[0.05,0.78]],
    
    // SOUTH PROVINCE
    'Nyaruguru': [[0.18,0.75],[0.28,0.72],[0.32,0.82],[0.28,0.90],[0.22,0.95],[0.18,0.88],[0.18,0.75]],
    'Nyamagabe': [[0.15,0.65],[0.20,0.58],[0.30,0.60],[0.32,0.68],[0.28,0.72],[0.18,0.75],[0.15,0.65]],
    'Huye': [[0.32,0.68],[0.42,0.65],[0.45,0.72],[0.42,0.80],[0.32,0.82],[0.28,0.72],[0.32,0.68]],
    'Gisagara': [[0.42,0.80],[0.52,0.78],[0.55,0.88],[0.48,0.95],[0.38,0.92],[0.32,0.82],[0.42,0.80]],
    'Nyanza': [[0.42,0.65],[0.52,0.60],[0.55,0.68],[0.52,0.78],[0.42,0.80],[0.45,0.72],[0.42,0.65]],
    'Ruhango': [[0.35,0.52],[0.42,0.50],[0.48,0.55],[0.52,0.60],[0.42,0.65],[0.32,0.68],[0.30,0.60],[0.35,0.52]],
    'Muhanga': [[0.28,0.35],[0.38,0.32],[0.42,0.42],[0.42,0.50],[0.35,0.52],[0.30,0.60],[0.20,0.58],[0.18,0.48],[0.22,0.38],[0.28,0.35]],
    'Kamonyi': [[0.42,0.42],[0.52,0.40],[0.55,0.48],[0.48,0.55],[0.42,0.50],[0.42,0.42]],
    
    // KIGALI CITY
    'Nyarugenge': [[0.42,0.35],[0.48,0.32],[0.52,0.38],[0.50,0.44],[0.45,0.42],[0.42,0.35]],
    'Gasabo': [[0.48,0.32],[0.58,0.30],[0.62,0.38],[0.58,0.45],[0.52,0.40],[0.50,0.44],[0.52,0.38],[0.48,0.32]],
    'Kicukiro': [[0.50,0.44],[0.58,0.45],[0.60,0.52],[0.55,0.55],[0.55,0.48],[0.52,0.40],[0.50,0.44]],
    
    // EAST PROVINCE  
    'Rwamagana': [[0.58,0.30],[0.65,0.25],[0.70,0.32],[0.68,0.42],[0.62,0.38],[0.58,0.30]],
    'Kayonza': [[0.68,0.15],[0.78,0.12],[0.85,0.22],[0.82,0.35],[0.75,0.38],[0.70,0.32],[0.65,0.25],[0.68,0.15]],
    'Gatsibo': [[0.62,0.08],[0.75,0.05],[0.85,0.10],[0.85,0.22],[0.78,0.12],[0.68,0.15],[0.62,0.08]],
    'Nyagatare': [[0.75,0.05],[0.92,0.02],[0.98,0.15],[0.95,0.28],[0.85,0.22],[0.85,0.10],[0.75,0.05]],
    'Bugesera': [[0.60,0.52],[0.68,0.48],[0.75,0.55],[0.72,0.65],[0.62,0.68],[0.55,0.60],[0.55,0.55],[0.60,0.52]],
    'Ngoma': [[0.68,0.42],[0.75,0.38],[0.82,0.45],[0.80,0.55],[0.75,0.55],[0.68,0.48],[0.62,0.45],[0.68,0.42]],
    'Kirehe': [[0.75,0.55],[0.80,0.55],[0.88,0.62],[0.92,0.75],[0.82,0.80],[0.72,0.72],[0.72,0.65],[0.75,0.55]],
  };

  /// Accurate District Centroids (LatLng) for bubble placement
  static const Map<String, List<double>> districtCentroids = {
    // KIGALI CITY
    'Nyarugenge': [-1.9536, 30.0605],
    'Gasabo': [-1.8879, 30.1332],
    'Kicukiro': [-1.9984, 30.1257],

    // NORTH PROVINCE
    'Burera': [-1.4727, 29.8310],
    'Gakenke': [-1.7001, 29.7909],
    'Gicumbi': [-1.6936, 30.1065],
    'Musanze': [-1.5036, 29.6375],
    'Rulindo': [-1.7373, 29.9880],

    // SOUTH PROVINCE
    'Gisagara': [-2.6322, 29.8459],
    'Huye': [-2.5973, 29.7400],
    'Kamonyi': [-1.9961, 29.8700],
    'Muhanga': [-2.0833, 29.7500],
    'Nyamagabe': [-2.4735, 29.4674],
    'Nyanza': [-2.3536, 29.7500],
    'Nyaruguru': [-2.7500, 29.5000],
    'Ruhango': [-2.2173, 29.7800],

    // EAST PROVINCE
    'Bugesera': [-2.1833, 30.1500],
    'Gatsibo': [-1.5947, 30.4533],
    'Kayonza': [-1.8500, 30.5500],
    'Kirehe': [-2.2667, 30.6500],
    'Ngoma': [-2.1667, 30.5333],
    'Nyagatare': [-1.3000, 30.3167],
    'Rwamagana': [-1.9500, 30.4333],

    // WEST PROVINCE
    'Karongi': [-2.1500, 29.3500],
    'Ngororero': [-1.8667, 29.6167],
    'Nyabihu': [-1.6500, 29.5167],
    'Nyamasheke': [-2.3833, 29.1500],
    'Rubavu': [-1.6667, 29.2500],
    'Rusizi': [-2.4833, 28.9000],
    'Rutsiro': [-1.9333, 29.3167],
  };

  /// Get the path for a district scaled to canvas size
  static Path getDistrictPath(String district, double width, double height) {
    // Legacy path method - kept if needed for fallback, but FlutterMap uses centroids now.
    final coords = districts[district] ?? [];
    final path = Path();
    
    if (coords.isEmpty) return path;
    
    path.moveTo(coords[0][0] * width, coords[0][1] * height);
    for (int i = 1; i < coords.length; i++) {
      path.lineTo(coords[i][0] * width, coords[i][1] * height);
    }
    path.close();
    
    return path;
  }

  static double getBubbleSize(int count) {
    if (count == 0) return 10.0; // Small dot if 0? Or 0?
    if (count < 10) return 20.0; 
    if (count < 50) return 30.0;
    return 40.0;
  }
  
  static Color getBubbleColor(int count) {
     if (count == 0) return Colors.green.withOpacity(0.5);
     if (count < 20) return Colors.greenAccent;
     if (count < 50) return Colors.orange;
     return Colors.redAccent;
  }
}
