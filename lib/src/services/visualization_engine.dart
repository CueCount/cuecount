import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:math' as math;

// Data models
class GraphEnvironment3D {
  final String id;
  final vector.Vector3 position;
  final String name;
  final List<DataPlot3D> plots = [];
  
  GraphEnvironment3D({
    required this.id,
    required this.position,
    required this.name,
  });
}

class DataPlot3D {
  final List<DataPoint3D> data;
  final Color color;
  final String fieldName;
  
  DataPlot3D({
    required this.data,
    required this.color,
    required this.fieldName,
  });
}

class DataPoint3D {
  final double x;
  final double y;
  final double z;
  final String label;
  final dynamic value;
  
  DataPoint3D({
    required this.x,
    required this.y,
    required this.z,
    required this.label,
    this.value,
  });
}

// Main visualization engine service
class VisualizationEngineService {
  // Graph environments management
  static List<GraphEnvironment3D> environments = [];
  static GraphEnvironment3D? selectedEnvironment;
  static int environmentCounter = 0;
  
  // Camera and view settings
  static double rotationX = -0.5;
  static double rotationY = 0.5;
  static double rotationZ = 0.0;
  static double zoom = 1.0;
  static double panX = 0.0;
  static double panY = 0.0;
  
  // Create new environment
  static GraphEnvironment3D addNewEnvironment() {
    final env = GraphEnvironment3D(
      id: 'env_${environmentCounter++}',
      position: vector.Vector3(
        environments.length * 300.0,
        0,
        0,
      ),
      name: 'Environment ${environments.length + 1}',
    );
    
    environments.add(env);
    selectedEnvironment = env;
    return env;
  }
  
  // Select environment
  static void selectEnvironment(GraphEnvironment3D env) {
    selectedEnvironment = env;
  }
  
  // Add sample data to environment
  static void addSampleDataToEnvironment(GraphEnvironment3D env) {
    final random = math.Random();
    final data = <DataPoint3D>[];
    
    for (int i = 0; i < 20; i++) {
      data.add(DataPoint3D(
        x: random.nextDouble() * 100 - 50,
        y: random.nextDouble() * 100 - 50,
        z: random.nextDouble() * 100 - 50,
        label: 'Point ${i + 1}',
        value: random.nextDouble() * 1000,
      ));
    }
    
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];
    
    env.plots.add(DataPlot3D(
      data: data,
      color: colors[env.plots.length % colors.length],
      fieldName: 'Sample Data ${env.plots.length + 1}',
    ));
  }

  static void reorderEnvironments(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = environments.removeAt(oldIndex);
    environments.insert(newIndex, item);
    
    // Update positions based on new order
    for (int i = 0; i < environments.length; i++) {
      environments[i].position.x = i * 300.0;
    }
  }
  
  // Reset view
  static void resetView() {
    rotationX = -0.5;
    rotationY = 0.5;
    rotationZ = 0.0;
    zoom = 1.0;
    panX = 0.0;
    panY = 0.0;
  }
  
  // Focus on selected environment
  static void focusOnSelected() {
    if (selectedEnvironment != null) {
      panX = -selectedEnvironment!.position.x;
      panY = -selectedEnvironment!.position.y;
    }
  }
}

// 3D Visualization Painter
class Visualization3DPainter extends CustomPainter {
  List<GraphEnvironment3D> environments;
  final GraphEnvironment3D? selectedEnvironment;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double zoom;
  final double panX;
  final double panY;
  
  Visualization3DPainter({
    required this.environments,
    this.selectedEnvironment,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.zoom,
    required this.panX,
    required this.panY,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx + panX, center.dy + panY);
    
    // Apply transformations
    final transform = vector.Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(rotationX)
      ..rotateY(rotationY)
      ..rotateZ(rotationZ)
      ..scale(zoom);
    
    // Draw each environment
    for (var environment in environments) {
      _drawEnvironment(
        canvas,
        environment,
        transform,
        environment == selectedEnvironment,
      );
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
    
    // Always draw grid
    _drawGrid(canvas, envTransform);
    
    // Always draw axes
    _drawAxes(canvas, envTransform, isSelected);
    
    // Draw plots
    for (var plot in environment.plots) {
      _drawScatterPlot(canvas, plot, envTransform);
    }
    
    // Draw environment label
    _drawEnvironmentLabel(canvas, environment, envTransform);
    
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
      
      // Horizontal lines
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
      
      // Vertical lines
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
    final xPaint = Paint()
      ..color = Colors.red.withOpacity(opacity)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    
    final xStart = _transform3DPoint(
      vector.Vector3(-axisLength / 2, 0, 0),
      transform,
    );
    final xEnd = _transform3DPoint(
      vector.Vector3(axisLength / 2, 0, 0),
      transform,
    );
    
    if (xStart != null && xEnd != null) {
      canvas.drawLine(xStart, xEnd, xPaint);
      _drawAxisLabel(canvas, 'X', xEnd, Colors.red);
    }
    
    // Y axis - Green
    final yPaint = Paint()
      ..color = Colors.green.withOpacity(opacity)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    
    final yStart = _transform3DPoint(
      vector.Vector3(0, -axisLength / 2, 0),
      transform,
    );
    final yEnd = _transform3DPoint(
      vector.Vector3(0, axisLength / 2, 0),
      transform,
    );
    
    if (yStart != null && yEnd != null) {
      canvas.drawLine(yStart, yEnd, yPaint);
      _drawAxisLabel(canvas, 'Y', yEnd, Colors.green);
    }
    
    // Z axis - Blue
    final zPaint = Paint()
      ..color = Colors.blue.withOpacity(opacity)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    
    final zStart = _transform3DPoint(
      vector.Vector3(0, 0, -axisLength / 2),
      transform,
    );
    final zEnd = _transform3DPoint(
      vector.Vector3(0, 0, axisLength / 2),
      transform,
    );
    
    if (zStart != null && zEnd != null) {
      canvas.drawLine(zStart, zEnd, zPaint);
      _drawAxisLabel(canvas, 'Z', zEnd, Colors.blue);
    }
    
    // Draw selection indicator if selected
    if (isSelected) {
      _drawSelectionBox(canvas, transform);
    }
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
      // Draw box edges
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
  
  void _drawEnvironmentLabel(Canvas canvas, GraphEnvironment3D environment, vector.Matrix4 transform) {
    final labelPos = _transform3DPoint(
      vector.Vector3(0, -60, 0),
      transform,
    );
    
    if (labelPos != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: environment.name,
          style: TextStyle(
            color: environment == selectedEnvironment
                ? Colors.white
                : Colors.white70,
            fontSize: 14,
            fontWeight: environment == selectedEnvironment
                ? FontWeight.bold
                : FontWeight.normal,
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
  
  Offset? _transform3DPoint(vector.Vector3 point, vector.Matrix4 transform) {
    final transformed = transform.transform3(point);
    
    // Perspective projection
    if (transformed.z < -500) return null; // Behind camera
    
    final perspective = 1 / (1 + transformed.z * 0.001);
    
    return Offset(
      transformed.x * perspective,
      transformed.y * perspective,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}