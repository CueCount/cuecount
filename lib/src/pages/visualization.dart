import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/menu.dart';
import '../../styles.dart';

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

class _VisualizationPageState extends State<VisualizationPage> {
  late VisualizationState vizState;
  
  @override
  void initState() {
    super.initState();
    vizState = VisualizationState();
  }
  
  @override
  void dispose() {
    vizState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Row(
            children: [
              Container (
                color: const Color.fromARGB(255, 255, 255, 255),
                alignment: Alignment.topCenter,
                margin: EdgeInsets.only(
                  top:20,
                  left:20,
                ),
                child: VisualizationMenu(
                  user: widget.user,
                  vizState: vizState,
                ),
              ),
              
              // Main Visualization Area
              Expanded(
                child: Container(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Stack(
                    children: [
                      // Placeholder for visualization
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
                                  'Visualization Engine Placeholder',
                                  style: AppTextStyles.subMedium.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Graph will render here',
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Switch to Graph button (top right of viz area)
                      Positioned(
                        top: 24,
                        right: 24,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle switch to graph
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Switch to Graph',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
  
  Widget _buildViewTab(String label, bool isActive, VoidCallback onTap, {bool isHighlighted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted ? Colors.cyan : (isActive ? Colors.black : Colors.grey.shade600),
          ),
        ),
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
          Text(
            'Document',
          ),

          const SizedBox(width: 30),
          
          // Graph View
          Text(
            'Graph',
          ),

          const SizedBox(width: 20),
          
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              // Zoom in
            },
          ),

          const SizedBox(width: 20),

          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              // Zoom out
            },
          ),

          const SizedBox(width: 20),

          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              // Toggle fullscreen
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isHighlighted = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: isHighlighted ? Colors.cyan : (isActive ? Colors.black : Colors.grey.shade600),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isHighlighted ? Colors.cyan : (isActive ? Colors.black : Colors.grey.shade600),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(),
      icon: Icon(
        icon,
        size: 20,
        color: Colors.grey.shade700,
      ),
    );
  }
}