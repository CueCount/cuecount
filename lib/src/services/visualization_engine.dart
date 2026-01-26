import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:math' as math;

// ============ DATA MODELS ============

/// Represents a 3D graph environment/workspace
class GraphEnvironment3D {
  final String id;
  final String name;
  final vector.Vector3 position;
  final List<DataPlot3D> plots;
  
  GraphEnvironment3D({
    required this.id,
    required this.name,
    vector.Vector3? position,
    List<DataPlot3D>? plots,
  }) : position = position ?? vector.Vector3.zero(),
       plots = plots ?? [];
  
  /// Create a copy with updated fields
  GraphEnvironment3D copyWith({
    String? id,
    String? name,
    vector.Vector3? position,
    List<DataPlot3D>? plots,
  }) {
    return GraphEnvironment3D(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      plots: plots ?? this.plots,
    );
  }
}

/// Represents a single data series/plot within an environment
class DataPlot3D {
  final String id;
  final String fieldName;
  final List<DataPoint3D> data;
  final Color color;
  final PlotType plotType;
  final bool visible;
  
  DataPlot3D({
    required this.id,
    required this.fieldName,
    required this.data,
    required this.color,
    this.plotType = PlotType.scatter,
    this.visible = true,
  });
  
  DataPlot3D copyWith({
    String? id,
    String? fieldName,
    List<DataPoint3D>? data,
    Color? color,
    PlotType? plotType,
    bool? visible,
  }) {
    return DataPlot3D(
      id: id ?? this.id,
      fieldName: fieldName ?? this.fieldName,
      data: data ?? this.data,
      color: color ?? this.color,
      plotType: plotType ?? this.plotType,
      visible: visible ?? this.visible,
    );
  }
}

/// A single 3D data point
class DataPoint3D {
  final double x;
  final double y;
  final double z;
  final String label;
  final dynamic value;
  final String? date;
  
  const DataPoint3D({
    required this.x,
    required this.y,
    required this.z,
    required this.label,
    this.value,
    this.date,
  });
}

/// Types of plots the engine can render
enum PlotType {
  scatter,
  line,
  bar,
  surface,
}

/// Camera/view state for the 3D visualization
class CameraState {
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double zoom;
  final double panX;
  final double panY;
  
  const CameraState({
    this.rotationX = -0.5,
    this.rotationY = 0.5,
    this.rotationZ = 0.0,
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
  });
  
  /// Default camera state
  static const CameraState initial = CameraState();
  
  CameraState copyWith({
    double? rotationX,
    double? rotationY,
    double? rotationZ,
    double? zoom,
    double? panX,
    double? panY,
  }) {
    return CameraState(
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      rotationZ: rotationZ ?? this.rotationZ,
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
    );
  }
  
  /// Apply rotation delta
  CameraState rotate(double deltaX, double deltaY) {
    return copyWith(
      rotationX: rotationX - deltaY * 0.01,
      rotationY: rotationY + deltaX * 0.01,
    );
  }
  
  /// Apply pan delta
  CameraState pan(double deltaX, double deltaY) {
    return copyWith(
      panX: panX + deltaX * 2,
      panY: panY - deltaY * 2,
    );
  }
  
  /// Apply zoom delta
  CameraState zoomBy(double delta) {
    return copyWith(
      zoom: (zoom - delta * 0.001).clamp(0.5, 5.0),
    );
  }
  
  /// Zoom in by factor
  CameraState zoomIn([double factor = 1.2]) {
    return copyWith(
      zoom: (zoom * factor).clamp(0.5, 5.0),
    );
  }
  
  /// Zoom out by factor
  CameraState zoomOut([double factor = 0.8]) {
    return copyWith(
      zoom: (zoom * factor).clamp(0.5, 5.0),
    );
  }
}


// ============ 3D VISUALIZATION PAINTER ============

/// CustomPainter that renders 3D environments and plots
class Visualization3DPainter extends CustomPainter {
  final List<GraphEnvironment3D> environments;
  final String? selectedEnvironmentId;
  final CameraState camera;
  
  Visualization3DPainter({
    required this.environments,
    this.selectedEnvironmentId,
    required this.camera,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx + camera.panX, center.dy + camera.panY);
    
    // Build transformation matrix
    final transform = vector.Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(camera.rotationX)
      ..rotateY(camera.rotationY)
      ..rotateZ(camera.rotationZ)
      ..scale(camera.zoom);
    
    // Draw each environment
    for (var environment in environments) {
      final isSelected = environment.id == selectedEnvironmentId;
      _drawEnvironment(canvas, environment, transform, isSelected);
    }
  }
  
  void _drawEnvironment(
    Canvas canvas,
    GraphEnvironment3D environment,
    vector.Matrix4 transform,
    bool isSelected,
  ) {
    canvas.save();
    
    // Translate to environment position
    final envTransform = transform.clone()
      ..translate(
        environment.position.x,
        environment.position.y,
        environment.position.z,
      );
    
    // Draw grid
    _drawGrid(canvas, envTransform);
    
    // Draw axes
    _drawAxes(canvas, envTransform, isSelected);
    
    // Draw plots
    for (var plot in environment.plots) {
      if (plot.visible) {
        switch (plot.plotType) {
          case PlotType.scatter:
            _drawScatterPlot(canvas, plot, envTransform);
            break;
          case PlotType.line:
            _drawLinePlot(canvas, plot, envTransform);
            break;
          case PlotType.bar:
            _drawBarPlot(canvas, plot, envTransform);
            break;
          case PlotType.surface:
            _drawScatterPlot(canvas, plot, envTransform); // Fallback
            break;
        }
      }
    }
    
    // Draw environment label
    _drawEnvironmentLabel(canvas, environment, envTransform, isSelected);
    
    // Draw selection indicator
    if (isSelected) {
      _drawSelectionBox(canvas, envTransform);
    }
    
    canvas.restore();
  }
  
  void _drawGrid(Canvas canvas, vector.Matrix4 transform) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    const gridSize = 100.0;
    const gridLines = 10;
    const step = gridSize / gridLines;
    
    for (int i = 0; i <= gridLines; i++) {
      final offset = -gridSize / 2 + i * step;
      
      // Horizontal lines (along X axis)
      final h1 = _transform3DPoint(
        vector.Vector3(-gridSize / 2, 0, offset),
        transform,
      );
      final h2 = _transform3DPoint(
        vector.Vector3(gridSize / 2, 0, offset),
        transform,
      );
      
      if (h1 != null && h2 != null) {
        canvas.drawLine(h1, h2, paint);
      }
      
      // Vertical lines (along Z axis)
      final v1 = _transform3DPoint(
        vector.Vector3(offset, 0, -gridSize / 2),
        transform,
      );
      final v2 = _transform3DPoint(
        vector.Vector3(offset, 0, gridSize / 2),
        transform,
      );
      
      if (v1 != null && v2 != null) {
        canvas.drawLine(v1, v2, paint);
      }
    }
  }
  
  void _drawAxes(Canvas canvas, vector.Matrix4 transform, bool isSelected) {
    const axisLength = 100.0;
    final lineWidth = isSelected ? 2.5 : 2.0;
    final opacity = isSelected ? 1.0 : 0.7;
    
    // X axis - Red
    _drawAxis(
      canvas, transform,
      vector.Vector3(-axisLength / 2, 0, 0),
      vector.Vector3(axisLength / 2, 0, 0),
      Colors.red.withOpacity(opacity),
      lineWidth,
      'X',
    );
    
    // Y axis - Green
    _drawAxis(
      canvas, transform,
      vector.Vector3(0, -axisLength / 2, 0),
      vector.Vector3(0, axisLength / 2, 0),
      Colors.green.withOpacity(opacity),
      lineWidth,
      'Y',
    );
    
    // Z axis - Blue
    _drawAxis(
      canvas, transform,
      vector.Vector3(0, 0, -axisLength / 2),
      vector.Vector3(0, 0, axisLength / 2),
      Colors.blue.withOpacity(opacity),
      lineWidth,
      'Z',
    );
  }
  
  void _drawAxis(
    Canvas canvas,
    vector.Matrix4 transform,
    vector.Vector3 start,
    vector.Vector3 end,
    Color color,
    double lineWidth,
    String label,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    
    final startPoint = _transform3DPoint(start, transform);
    final endPoint = _transform3DPoint(end, transform);
    
    if (startPoint != null && endPoint != null) {
      canvas.drawLine(startPoint, endPoint, paint);
      _drawAxisLabel(canvas, label, endPoint, color);
    }
  }
  
  void _drawAxisLabel(Canvas canvas, String label, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(canvas, position);
  }
  
  void _drawSelectionBox(Canvas canvas, vector.Matrix4 transform) {
    final boxPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    const boxSize = 110.0;
    final corners = [
      vector.Vector3(-boxSize / 2, -boxSize / 2, -boxSize / 2),
      vector.Vector3(boxSize / 2, -boxSize / 2, -boxSize / 2),
      vector.Vector3(boxSize / 2, boxSize / 2, -boxSize / 2),
      vector.Vector3(-boxSize / 2, boxSize / 2, -boxSize / 2),
      vector.Vector3(-boxSize / 2, -boxSize / 2, boxSize / 2),
      vector.Vector3(boxSize / 2, -boxSize / 2, boxSize / 2),
      vector.Vector3(boxSize / 2, boxSize / 2, boxSize / 2),
      vector.Vector3(-boxSize / 2, boxSize / 2, boxSize / 2),
    ];
    
    final transformedCorners = corners
        .map((c) => _transform3DPoint(c, transform))
        .where((p) => p != null)
        .cast<Offset>()
        .toList();
    
    if (transformedCorners.length == 8) {
      final edges = [
        [0, 1], [1, 2], [2, 3], [3, 0], // Front face
        [4, 5], [5, 6], [6, 7], [7, 4], // Back face
        [0, 4], [1, 5], [2, 6], [3, 7], // Connecting edges
      ];
      
      for (var edge in edges) {
        canvas.drawLine(
          transformedCorners[edge[0]],
          transformedCorners[edge[1]],
          boxPaint,
        );
      }
    }
  }
  
  void _drawScatterPlot(Canvas canvas, DataPlot3D plot, vector.Matrix4 transform) {
    final paint = Paint()
      ..color = plot.color
      ..style = PaintingStyle.fill;
    
    for (var point in plot.data) {
      final pos = _transform3DPoint(
        vector.Vector3(point.x, -point.y, point.z),
        transform,
      );
      
      if (pos != null) {
        canvas.drawCircle(pos, 4.0, paint);
      }
    }
  }
  
  void _drawLinePlot(Canvas canvas, DataPlot3D plot, vector.Matrix4 transform) {
    if (plot.data.length < 2) return;
    
    final paint = Paint()
      ..color = plot.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    bool started = false;
    
    for (var point in plot.data) {
      final pos = _transform3DPoint(
        vector.Vector3(point.x, -point.y, point.z),
        transform,
      );
      
      if (pos != null) {
        if (!started) {
          path.moveTo(pos.dx, pos.dy);
          started = true;
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw points on top
    final pointPaint = Paint()
      ..color = plot.color
      ..style = PaintingStyle.fill;
    
    for (var point in plot.data) {
      final pos = _transform3DPoint(
        vector.Vector3(point.x, -point.y, point.z),
        transform,
      );
      
      if (pos != null) {
        canvas.drawCircle(pos, 3.0, pointPaint);
      }
    }
  }
  
  void _drawBarPlot(Canvas canvas, DataPlot3D plot, vector.Matrix4 transform) {
    final paint = Paint()
      ..color = plot.color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = plot.color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    for (var point in plot.data) {
      final top = _transform3DPoint(
        vector.Vector3(point.x, -point.y, point.z),
        transform,
      );
      final bottom = _transform3DPoint(
        vector.Vector3(point.x, 0, point.z),
        transform,
      );
      
      if (top != null && bottom != null) {
        final barWidth = 6.0;
        final rect = Rect.fromPoints(
          Offset(top.dx - barWidth / 2, top.dy),
          Offset(bottom.dx + barWidth / 2, bottom.dy),
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
      }
    }
  }
  
  void _drawEnvironmentLabel(
    Canvas canvas,
    GraphEnvironment3D environment,
    vector.Matrix4 transform,
    bool isSelected,
  ) {
    final labelPos = _transform3DPoint(
      vector.Vector3(0, -70, 0),
      transform,
    );
    
    if (labelPos != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: environment.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      // Draw background
      final bgRect = Rect.fromCenter(
        center: labelPos,
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      );
      
      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        bgPaint,
      );
      
      // Draw text
      textPainter.paint(
        canvas,
        labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }
  
  Offset? _transform3DPoint(vector.Vector3 point, vector.Matrix4 transform) {
    final transformed = transform.transform3(point);
    
    // Perspective projection - cull points behind camera
    if (transformed.z < -500) return null;
    
    final perspective = 1 / (1 + transformed.z * 0.001);
    
    return Offset(
      transformed.x * perspective,
      transformed.y * perspective,
    );
  }
  
  @override
  bool shouldRepaint(covariant Visualization3DPainter oldDelegate) {
    return environments != oldDelegate.environments ||
           selectedEnvironmentId != oldDelegate.selectedEnvironmentId ||
           camera != oldDelegate.camera;
  }
}


// ============ UTILITY FUNCTIONS ============

/// Helper to generate sample data for testing
List<DataPoint3D> generateSampleData({
  int count = 20,
  double range = 50,
  int seed = 0,
}) {
  final random = math.Random(seed);
  final data = <DataPoint3D>[];
  
  for (int i = 0; i < count; i++) {
    data.add(DataPoint3D(
      x: random.nextDouble() * range * 2 - range,
      y: random.nextDouble() * range * 2 - range,
      z: random.nextDouble() * range * 2 - range,
      label: 'Point ${i + 1}',
      value: random.nextDouble() * 1000,
    ));
  }
  
  return data;
}

/// Color palette for plots
class PlotColors {
  static const List<Color> palette = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
    Color(0xFFFFEB3B), // Yellow
  ];
  
  static Color getColor(int index) {
    return palette[index % palette.length];
  }
}