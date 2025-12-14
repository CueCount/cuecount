import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/menu.dart';
import '../../styles.dart';
import '../services/visualization_engine.dart';

// Visualization State Class for future viz engine
class VisualizationState extends ChangeNotifier {
  // View modes
  bool isYourView = true;
  bool isCurrentView = false;
  bool isExploreView = false;
  
  // Selected items/filters
  String? selectedStock;
  List<String> selectedTags = [];
  
  // Graph data (placeholder for now)
  Map<String, dynamic> graphData = {};
  
  // Update view mode
  void setViewMode({bool yours = false, bool current = false, bool explore = false}) {
    isYourView = yours;
    isCurrentView = current;
    isExploreView = explore;
    notifyListeners();
  }
  
  // Add methods for viz engine
  void updateGraphData(Map<String, dynamic> data) {
    graphData = data;
    notifyListeners();
  }
  
  void selectStock(String stock) {
    selectedStock = stock;
    notifyListeners();
  }
  
  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    notifyListeners();
  }
  
  void clearSelection() {
    selectedStock = null;
    selectedTags.clear();
    notifyListeners();
  }
}

class VisualizationPage extends StatefulWidget {
  final User? user;
  const VisualizationPage({super.key, this.user});

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> 
    with TickerProviderStateMixin {
  late VisualizationState vizState;
  
  // 3D Visualization Controllers
  late AnimationController _rotationController;
  bool _autoRotate = false;
  Offset? _lastPanPosition;
  bool _showGraphView = false;
  bool _isRightMouseButton = false;
  
  @override
  void initState() {
    super.initState();
    vizState = VisualizationState();
    
    // Initialize 3D controls
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Initialize with one environment
    if (VisualizationEngineService.environments.isEmpty) {
      VisualizationEngineService.addNewEnvironment();
      // Add sample data to test
      VisualizationEngineService.addSampleDataToEnvironment(
        VisualizationEngineService.environments.first
      );
    }
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    vizState.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.globalPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition != null) {
      final delta = details.globalPosition - _lastPanPosition!;
      
      setState(() {
        if (_isRightMouseButton) { // Right mouse button for pan
          VisualizationEngineService.panX += delta.dx * 2;
          VisualizationEngineService.panY -= delta.dy * 2;
        } else { // Left mouse button for rotate
          VisualizationEngineService.rotationY += delta.dx * 0.01;
          VisualizationEngineService.rotationX -= delta.dy * 0.01;
        }
      });
      
      _lastPanPosition = details.globalPosition;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Visualization Area
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: Stack(
                children: [
                  // 3D Visualization or Placeholder
                  if (_showGraphView)
                    Listener(
                      onPointerDown: (event) {
                        _isRightMouseButton = event.buttons == 2;
                      },

                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          setState(() {
                            final scrollDelta = pointerSignal.scrollDelta.dy;
                            VisualizationEngineService.zoom = 
                              (VisualizationEngineService.zoom - scrollDelta * 0.001)
                                .clamp(0.5, 5.0);
                          });
                        }
                      },

                      child: GestureDetector(
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        child: Container(
                          color: Colors.white,
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {

                              if (_autoRotate) {
                                VisualizationEngineService.rotationY = 
                                  _rotationController.value * 2 * 3.14159;
                              }
                              
                              return CustomPaint(
                                painter: Visualization3DPainter(
                                  environments: VisualizationEngineService.environments,
                                  selectedEnvironment: VisualizationEngineService.selectedEnvironment,
                                  rotationX: VisualizationEngineService.rotationX,
                                  rotationY: VisualizationEngineService.rotationY,
                                  rotationZ: VisualizationEngineService.rotationZ,
                                  zoom: VisualizationEngineService.zoom,
                                  panX: VisualizationEngineService.panX,
                                  panY: VisualizationEngineService.panY,
                                ),
                                size: Size.infinite,
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bubble_chart,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Visualization Engine',
                                style: AppTextStyles.subMedium.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Switch to Graph" to view 3D visualization',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                ],
              ),
            ),
          ),
        
          // Menu (absolute positioned on top left)
          Positioned(
            top: 20,
            left: 20,
            child: VisualizationMenu(
              user: widget.user,
              vizState: vizState,
            ),
          ),
          
          // Floating Controls (Bottom Left)
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildFloatingControls(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingControls() {
    return Container(
      padding: EdgeInsets.all(20),
      width: 420,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document/Table View
          GestureDetector(
            onTap: () {
              setState(() {
                _showGraphView = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !_showGraphView ? Colors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Document',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: !_showGraphView ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Graph View
          GestureDetector(
            onTap: () {
              setState(() {
                _showGraphView = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _showGraphView ? Colors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Graph',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _showGraphView ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                VisualizationEngineService.zoom = 
                  (VisualizationEngineService.zoom * 1.2).clamp(0.5, 5.0);
              });
            },
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                VisualizationEngineService.zoom = 
                  (VisualizationEngineService.zoom * 0.8).clamp(0.5, 5.0);
              });
            },
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              setState(() {
                VisualizationEngineService.resetView();
              });
            },
          ),
        ],
      ),
    );
  }

}