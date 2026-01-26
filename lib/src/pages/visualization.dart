import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/menu.dart';
import '../../styles.dart';
import '../services/visualization_engine.dart';
import '../providers/workspaceState.dart';

class VisualizationPage extends StatefulWidget {
  final User? user;
  const VisualizationPage({super.key, this.user});

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> 
    with TickerProviderStateMixin {
  
  // Camera state (local to this page)
  CameraState _camera = CameraState.initial;
  
  // Interaction state
  Offset? _lastPanPosition;
  bool _isRightMouseButton = false;
  
  // Auto-rotation
  late AnimationController _rotationController;
  bool _autoRotate = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize rotation controller for auto-rotate feature
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Initialize workspace state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workspace = Provider.of<WorkspaceState>(context, listen: false);
      workspace.initialize();
    });
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // ============ INTERACTION HANDLERS ============

  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.globalPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition != null) {
      final delta = details.globalPosition - _lastPanPosition!;
      
      setState(() {
        if (_isRightMouseButton) {
          // Right mouse button for pan
          _camera = _camera.pan(delta.dx, delta.dy);
        } else {
          // Left mouse button for rotate
          _camera = _camera.rotate(delta.dx, delta.dy);
        }
      });
      
      _lastPanPosition = details.globalPosition;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  void _handleScroll(PointerScrollEvent event) {
    setState(() {
      _camera = _camera.zoomBy(event.scrollDelta.dy);
    });
  }

  void _resetView() {
    setState(() {
      _camera = CameraState.initial;
    });
  }

  void _zoomIn() {
    setState(() {
      _camera = _camera.zoomIn();
    });
  }

  void _zoomOut() {
    setState(() {
      _camera = _camera.zoomOut();
    });
  }

  void _toggleAutoRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
      if (_autoRotate) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceState>(
      builder: (context, workspace, child) {
        final showGraphView = workspace.viewMode == ViewMode.graph;
        
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
                      if (showGraphView)
                        _buildGraphView(workspace)
                      else
                        _buildPlaceholder(context),
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
                ),
              ),
              
              // Floating Controls (Bottom Left)
              Positioned(
                bottom: 20,
                left: 20,
                child: _buildFloatingControls(workspace),
              ),
              
              // Loading overlay
              if (workspace.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              
              // Error message
              if (workspace.errorMessage != null)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: _buildErrorBanner(workspace),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildGraphView(WorkspaceState workspace) {
    return Listener(
      onPointerDown: (event) {
        _isRightMouseButton = event.buttons == 2;
      },
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          _handleScroll(pointerSignal);
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
              // Apply auto-rotation if enabled
              CameraState currentCamera = _camera;
              if (_autoRotate) {
                currentCamera = _camera.copyWith(
                  rotationY: _rotationController.value * 2 * 3.14159,
                );
              }
              
              return CustomPaint(
                painter: Visualization3DPainter(
                  environments: workspace.environments,
                  selectedEnvironmentId: workspace.currentEnvironmentId,
                  camera: currentCamera,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return Center(
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
                'Click "Graph" to view 3D visualization',
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingControls(WorkspaceState workspace) {
    final showGraphView = workspace.viewMode == ViewMode.graph;
    
    return Container(
      padding: const EdgeInsets.all(20),
      width: 420,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document View
          GestureDetector(
            onTap: () => workspace.setViewMode(ViewMode.document),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !showGraphView ? Colors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Document',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: !showGraphView ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Graph View
          GestureDetector(
            onTap: () => workspace.setViewMode(ViewMode.graph),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: showGraphView ? Colors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Graph',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: showGraphView ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
          // Zoom controls (only show in graph view)
          if (showGraphView) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomIn,
              tooltip: 'Zoom In',
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOut,
              tooltip: 'Zoom Out',
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: _resetView,
              tooltip: 'Reset View',
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                _autoRotate ? Icons.pause : Icons.play_arrow,
                color: _autoRotate ? Colors.cyan : null,
              ),
              onPressed: _toggleAutoRotate,
              tooltip: _autoRotate ? 'Stop Rotation' : 'Auto Rotate',
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildErrorBanner(WorkspaceState workspace) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                workspace.errorMessage ?? 'An error occurred',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => workspace.clearError(),
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }
}