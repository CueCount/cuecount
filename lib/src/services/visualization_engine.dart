import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'connections.dart' as dt;

class VisualizationEngine extends StatefulWidget {
  final List<DocumentSnapshot> documents;
  final String companyName;

  const VisualizationEngine({
    super.key,
    required this.documents,
    required this.companyName,
  });

  @override
  State<VisualizationEngine> createState() => _VisualizationEngineState();
}

class _VisualizationEngineState extends State<VisualizationEngine>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _animationController;
  
  // Data table and visualization data
  late dt.DataTable _dataTable;
  late dt.TableVisualizationData _visualizationData;
  
  // 3D transformation parameters
  double _rotationX = 0.3;
  double _rotationY = 0.5;
  double _rotationZ = 0.0;
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  
  // Mouse/touch tracking
  Offset? _lastPointerPosition;
  bool _isPanning = false;
  
  // Selected data point
  DataPoint? _hoveredPoint;
  
  // Visualization settings
  bool _showGrid = true;
  bool _showAxes = true;
  bool _showLabels = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _initializeData() {
    // Build the data table from documents
    _dataTable = dt.DataTableBuilder.buildFromDocuments(widget.documents);
    _visualizationData = dt.TableVisualizationData.fromTable(_dataTable);
    
    print('Data table initialized:');
    print('  Quarters: ${_dataTable.quarters}');
    print('  Fields: ${_dataTable.numericFieldNames}');
    print('  Total connections: ${_visualizationData.connections.length}');
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main visualization canvas
        Listener(
          onPointerDown: (event) {
            _lastPointerPosition = event.localPosition;
            // Check if it's a secondary button (right click)
            _isPanning = event.buttons == 2;
          },

          onPointerMove: (event) {
            if (_lastPointerPosition != null) {
              final delta = event.localPosition - _lastPointerPosition!;
              
              setState(() {
                if (_isPanning) {
                  // Pan with right mouse button
                  _pan += delta;
                } else {
                  // Rotate with left mouse button
                  _rotationY += delta.dx * 0.01;
                  _rotationX += delta.dy * 0.01;
                }
              });
              
              _lastPointerPosition = event.localPosition;
            }
          },

          onPointerUp: (event) {
            _lastPointerPosition = null;
            _isPanning = false;
          },

          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              setState(() {
                final scrollDelta = event.scrollDelta;
                
                // Adjust zoom sensitivity based on platform
                // Trackpads typically have smaller deltas than mouse wheels
                double zoomFactor;
                if (scrollDelta.dy.abs() < 20) {
                  // Likely a trackpad (smooth scrolling)
                  zoomFactor = 0.002;
                } else {
                  // Likely a mouse wheel (discrete steps)
                  zoomFactor = 0.01;
                }
                
                // Apply zoom with the calculated factor
                final zoomDelta = 1 - (scrollDelta.dy * zoomFactor);
                _zoom = (_zoom * zoomDelta).clamp(0.1, 5.0);
              });
            }
          },

          onPointerHover: (event) {
            // Track hover position for potential tooltips
            _checkHover(event.localPosition);
          },
          
          child: GestureDetector(
            // Add pinch-to-zoom for trackpad
            onScaleStart: (details) {
              // Store initial zoom when gesture starts
            },
            onScaleUpdate: (details) {
              setState(() {
                // Apply pinch zoom
                _zoom = (_zoom * details.scale).clamp(0.1, 5.0);
              });
            },
            child: MouseRegion(
              cursor: _isPanning ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
              child: Container(
                color: Colors.black,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: TableVisualizationPainter(
                    dataTable: _dataTable,
                    visualizationData: _visualizationData,
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    rotationZ: _rotationZ,
                    zoom: _zoom,
                    pan: _pan,
                    showGrid: _showGrid,
                    showAxes: _showAxes,
                    showLabels: _showLabels,
                    hoveredPoint: _hoveredPoint,
                    animation: _animationController,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Hover tooltip
        ..._hoveredPoint != null ? [
          Positioned(
            left: _hoveredPoint!.screenPosition.dx + 10,
            top: _hoveredPoint!.screenPosition.dy + 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _hoveredPoint!.fieldName.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Value: ${_formatNumber(_hoveredPoint!.value)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  ..._hoveredPoint!.period != null ? [
                    Text(
                      'Period: ${_hoveredPoint!.period}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ] : [],
                ],
              ),
            ),
          ),
        ] : [],
        
        // Instructions overlay with zoom level indicator
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Left drag: Rotate • Right drag: Pan • Scroll: Zoom',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zoom: ${(_zoom * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        
        // Zoom controls buttons
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _zoom = (_zoom * 1.2).clamp(0.1, 5.0);
                    });
                  },
                  icon: const Icon(Icons.zoom_in, color: Colors.white),
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _zoom = (_zoom / 1.2).clamp(0.1, 5.0);
                    });
                  },
                  icon: const Icon(Icons.zoom_out, color: Colors.white),
                  tooltip: 'Zoom Out',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _zoom = 1.0;
                      _pan = Offset.zero;
                      _rotationX = 0.3;
                      _rotationY = 0.5;
                    });
                  },
                  icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                  tooltip: 'Reset View',
                ),
              ],
            ),
          ),
        ),
 
        
        // Hover tooltip
        if (_hoveredPoint != null)
          Positioned(
            left: _hoveredPoint!.screenPosition.dx + 10,
            top: _hoveredPoint!.screenPosition.dy + 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _hoveredPoint!.fieldName.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Value: ${_formatNumber(_hoveredPoint!.value)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  if (_hoveredPoint!.period != null)
                    Text(
                      'Period: ${_hoveredPoint!.period}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        
        // Instructions overlay
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Left drag: Rotate • Right drag: Pan • Scroll: Zoom',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
  
  void _checkHover(Offset position) {
    // This would check if the position is near any data point
    // For simplicity, we're not implementing full hit testing here
    setState(() {
      _hoveredPoint = null;
    });
  }
  
  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class TableVisualizationPainter extends CustomPainter {
  final dt.DataTable dataTable;
  final dt.TableVisualizationData visualizationData;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double zoom;
  final Offset pan;
  final bool showGrid;
  final bool showAxes;
  final bool showLabels;
  final DataPoint? hoveredPoint;
  final Animation<double> animation;

  TableVisualizationPainter({
    required this.dataTable,
    required this.visualizationData,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.zoom,
    required this.pan,
    required this.showGrid,
    required this.showAxes,
    required this.showLabels,
    this.hoveredPoint,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + pan;
    
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size, center);
    }
    
    // Draw axes if enabled
    if (showAxes) {
      _drawAxes(canvas, size, center);
    }
    
    // Draw the data table visualization
    _drawDataTable(canvas, size, center);
  }

  void _drawGrid(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 50.0;
    final gridCount = 10;

    for (int i = -gridCount; i <= gridCount; i++) {
      final point1 = _project3D(
        Point3D(i * gridSize, 0, -gridCount * gridSize),
        center,
      );
      final point2 = _project3D(
        Point3D(i * gridSize, 0, gridCount * gridSize),
        center,
      );
      canvas.drawLine(point1, point2, paint);

      final point3 = _project3D(
        Point3D(-gridCount * gridSize, 0, i * gridSize),
        center,
      );
      final point4 = _project3D(
        Point3D(gridCount * gridSize, 0, i * gridSize),
        center,
      );
      canvas.drawLine(point3, point4, paint);
    }
  }

  void _drawAxes(Canvas canvas, Size size, Offset center) {
    final axisPaint = Paint()
      ..strokeWidth = 2;

    // X-axis (red) - Time/Quarters
    axisPaint.color = Colors.red;
    canvas.drawLine(
      _project3D(Point3D(0, 0, 0), center),
      _project3D(Point3D(200, 0, 0), center),
      axisPaint,
    );

    // Y-axis (green) - Values
    axisPaint.color = Colors.green;
    canvas.drawLine(
      _project3D(Point3D(0, 0, 0), center),
      _project3D(Point3D(0, 200, 0), center),
      axisPaint,
    );

    // Z-axis (blue) - Different fields
    axisPaint.color = Colors.blue;
    canvas.drawLine(
      _project3D(Point3D(0, 0, 0), center),
      _project3D(Point3D(0, 0, 200), center),
      axisPaint,
    );
  }

  void _drawDataTable(Canvas canvas, Size size, Offset center) {
    final fieldColors = {
      'total_assets': Colors.green,
      'total_liabilities': Colors.red,
      'total_equity': Colors.blue,
      'net_income': Colors.orange,
      'revenue': Colors.purple,
      'cash': Colors.cyan,
      'accounts_payable': Colors.pink,
      'accounts_receivable': Colors.amber,
      'inventory': Colors.lime,
      'long_term_debt': Colors.deepOrange,
      'short_term_debt': Colors.indigo,
      'retained_earnings': Colors.teal,
    };

    final numericFields = dataTable.numericFieldNames;
    final quarterCount = dataTable.quarters.length;
    
    // Calculate spacing
    final xSpacing = 100.0; // Space between quarters
    final zSpacing = 60.0;  // Space between fields
    final xOffset = -(quarterCount - 1) * xSpacing / 2;
    final zOffset = -(numericFields.length - 1) * zSpacing / 2;
    
    // Use a consistent Y scale for all fields
    final yScale = 200.0; // Height scale for visualization

    // Draw each field as a line through quarters
    for (int fieldIndex = 0; fieldIndex < numericFields.length; fieldIndex++) {
      final fieldName = numericFields[fieldIndex];
      final row = dataTable.rows.firstWhere(
        (r) => r.fieldName == fieldName,
        orElse: () => dt.DataRow(fieldName: fieldName, cells: []),
      );
      
      if (row.cells.isEmpty) continue;
      
      final color = fieldColors[fieldName] ?? 
                   Colors.primaries[fieldIndex % Colors.primaries.length];
      final linePaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      final points = <Offset>[];
      final dataPoints = <DataPointInfo>[];
      
      // Draw points and collect positions
      for (int quarterIndex = 0; quarterIndex < row.cells.length; quarterIndex++) {
        final cell = row.cells[quarterIndex];
        final numericValue = cell.numericValue;
        
        if (numericValue == null) continue;
        
        // Calculate position
        final x = xOffset + quarterIndex * xSpacing;
        final z = zOffset + fieldIndex * zSpacing;
        
        // Use global normalization for consistent scale across all fields
        final normalizedValue = visualizationData.normalizeValueGlobal(numericValue);
        final y = -normalizedValue * yScale; // Negative because canvas Y is inverted
        
        final point3d = Point3D(x, y, z);
        final screenPoint = _project3D(point3d, center);
        points.add(screenPoint);
        
        // Store data point info for hover detection
        dataPoints.add(DataPointInfo(
          screenPosition: screenPoint,
          fieldName: fieldName,
          value: numericValue,
          quarter: dataTable.quarters[quarterIndex],
          documentId: cell.documentId,
        ));
        
        // Draw the data point
        canvas.drawCircle(screenPoint, 6, pointPaint);
        
        // Draw value label at each point for debugging
        if (showLabels && quarterIndex == 0) { // Only show at first point
          final valuePainter = TextPainter(
            text: TextSpan(
              text: _formatValue(numericValue),
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          valuePainter.layout();
          valuePainter.paint(canvas, screenPoint + const Offset(8, -8));
        }
      }
      
      // Draw connecting lines
      if (points.length > 1) {
        final path = Path();
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        canvas.drawPath(path, linePaint);
      }
      
      // Draw field label
      if (showLabels && points.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: fieldName.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, points.first - const Offset(0, 20));
      }
    }
    
    // Draw quarter labels on X-axis
    if (showLabels) {
      for (int i = 0; i < dataTable.quarters.length; i++) {
        final x = xOffset + i * xSpacing;
        final point = _project3D(Point3D(x, 20, -30), center);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: dataTable.quarters[i],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, point - Offset(textPainter.width / 2, 0));
      }
    }
    
    // Draw scale reference
    if (showGrid) {
      _drawScaleReference(canvas, size, center);
    }
  }
  
  void _drawScaleReference(Canvas canvas, Size size, Offset center) {
    // Draw Y-axis scale markers
    final scalePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    
    final min = visualizationData.globalMin;
    final max = visualizationData.globalMax;
    
    for (int i = 0; i <= 4; i++) {
      final value = min + (max - min) * i / 4;
      final normalizedValue = i / 4.0;
      final y = -normalizedValue * 200;
      
      final startPoint = _project3D(Point3D(-250, y, 0), center);
      final endPoint = _project3D(Point3D(-240, y, 0), center);
      
      canvas.drawLine(startPoint, endPoint, scalePaint);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatValue(value),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, startPoint - Offset(textPainter.width + 5, textPainter.height / 2));
    }
  }
  
  String _formatValue(double value) {
    if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T';
    } else if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Offset _project3D(Point3D point, Offset center) {
    // Apply rotations
    var rotated = point.rotateX(rotationX);
    rotated = rotated.rotateY(rotationY);
    rotated = rotated.rotateZ(rotationZ);

    // Apply zoom
    rotated = rotated.scale(zoom);

    // Simple perspective projection
    final perspective = 500;
    final factor = perspective / (perspective + rotated.z);
    
    return Offset(
      center.dx + rotated.x * factor,
      center.dy + rotated.y * factor,
    );
  }

  @override
  bool shouldRepaint(TableVisualizationPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY ||
           oldDelegate.rotationZ != rotationZ ||
           oldDelegate.zoom != zoom ||
           oldDelegate.pan != pan ||
           oldDelegate.hoveredPoint != hoveredPoint;
  }
}

class Point3D {
  final double x;
  final double y;
  final double z;

  Point3D(this.x, this.y, this.z);

  Point3D rotateX(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Point3D(
      x,
      y * cos - z * sin,
      y * sin + z * cos,
    );
  }

  Point3D rotateY(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Point3D(
      x * cos + z * sin,
      y,
      -x * sin + z * cos,
    );
  }

  Point3D rotateZ(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Point3D(
      x * cos - y * sin,
      x * sin + y * cos,
      z,
    );
  }

  Point3D scale(double factor) {
    return Point3D(x * factor, y * factor, z * factor);
  }
}

class DataPoint {
  final String fieldName;
  final double value;
  final String? period;
  final Offset screenPosition;

  DataPoint({
    required this.fieldName,
    required this.value,
    this.period,
    required this.screenPosition,
  });
}

class DataPointInfo {
  final Offset screenPosition;
  final String fieldName;
  final double value;
  final String quarter;
  final String documentId;
  
  DataPointInfo({
    required this.screenPosition,
    required this.fieldName,
    required this.value,
    required this.quarter,
    required this.documentId,
  });
}