import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vector_math/vector_math.dart' as vector;
import '../services/visualization_engine.dart';

// ============ TREND DATA MODEL ============

/// Represents a single trend/data field within a cluster
class TrendData {
  final String id;
  final String name;
  final String displayName;
  final List<Map<String, dynamic>> dataPoints;
  final Color color;
  bool isVisible;
  bool isSelected;

  TrendData({
    required this.id,
    required this.name,
    required this.displayName,
    required this.dataPoints,
    required this.color,
    this.isVisible = true,
    this.isSelected = false,
  });

  /// Create TrendData from a Firestore field entry
  factory TrendData.fromFirestore(String fieldName, dynamic fieldData, Color color) {
    List<Map<String, dynamic>> points = [];
    
    if (fieldData is Map) {
      // Convert map entries to data points
      fieldData.forEach((key, value) {
        points.add({
          'date': key,
          'value': value is num ? value.toDouble() : 0.0,
        });
      });
      
      // Sort by date
      points.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    } else if (fieldData is List) {
      points = List<Map<String, dynamic>>.from(fieldData);
    }

    return TrendData(
      id: fieldName,
      name: fieldName,
      displayName: _formatDisplayName(fieldName),
      dataPoints: points,
      color: color,
    );
  }

  /// Convert snake_case to Title Case
  static String _formatDisplayName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Get the latest value
  double? get latestValue {
    if (dataPoints.isEmpty) return null;
    return dataPoints.last['value'] as double?;
  }

  /// Get min/max for normalization
  double get minValue => dataPoints.isEmpty 
      ? 0 
      : dataPoints.map((p) => p['value'] as double).reduce((a, b) => a < b ? a : b);
  
  double get maxValue => dataPoints.isEmpty 
      ? 0 
      : dataPoints.map((p) => p['value'] as double).reduce((a, b) => a > b ? a : b);

  /// Convert to 3D plot for visualization engine
  DataPlot3D toPlot3D({int zIndex = 0, PlotType plotType = PlotType.line}) {
    final points = <DataPoint3D>[];
    
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final value = point['value'] as double? ?? 0;
      
      // Normalize value for visualization (map to -50 to 50 range)
      final normalizedY = maxValue != minValue
          ? ((value - minValue) / (maxValue - minValue) * 100) - 50
          : 0.0;
      
      points.add(DataPoint3D(
        x: (i / (dataPoints.length - 1).clamp(1, double.infinity) * 100) - 50,
        y: normalizedY,
        z: zIndex * 20.0, // Offset each trend on Z axis
        label: displayName,
        value: value,
        date: point['date'] as String?,
      ));
    }
    
    return DataPlot3D(
      id: id,
      fieldName: displayName,
      data: points,
      color: color,
      plotType: plotType,
      visible: isVisible,
    );
  }

}

// ============ CLUSTER DATA MODEL ============

/// Represents a cluster document from Firestore
class ClusterData {
  final String id;
  final String name;
  final String? ticker;
  final List<String> tags;
  final Map<String, TrendData> trends;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClusterData({
    required this.id,
    required this.name,
    this.ticker,
    required this.tags,
    required this.trends,
    this.createdAt,
    this.updatedAt,
  });

  /// Create ClusterData from Firestore document
  factory ClusterData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final dataMap = data['data'] as Map<String, dynamic>? ?? {};
    
    // Parse trends from the data map
    final Map<String, TrendData> trends = {};
    final colors = _generateColorPalette();
    
    int colorIndex = 0;
    dataMap.forEach((key, value) {
      trends[key] = TrendData.fromFirestore(key, value, colors[colorIndex % colors.length]);
      colorIndex++;
    });

    return ClusterData(
      id: doc.id,
      name: data['name'] ?? doc.id,
      ticker: data['ticker'],
      tags: List<String>.from(data['tags'] ?? []),
      trends: trends,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Generate a nice color palette for trends
  static List<Color> _generateColorPalette() {
    return PlotColors.palette;
  }

  /// Get list of trend names
  List<String> get trendNames => trends.keys.toList();

  /// Get visible trends (for visualization)
  List<TrendData> get visibleTrends =>
      trends.values.where((t) => t.isVisible).toList();

  /// Get selected trends
  List<TrendData> get selectedTrends =>
      trends.values.where((t) => t.isSelected).toList();

  /// Convert to 3D environment for visualization engine
  GraphEnvironment3D toEnvironment3D({
    vector.Vector3? position,
    PlotType plotType = PlotType.line,
  }) {
    final plots = <DataPlot3D>[];
    int zIndex = 0;
    
    for (final trend in visibleTrends) {
      plots.add(trend.toPlot3D(zIndex: zIndex, plotType: plotType));
      zIndex++;
    }
    
    return GraphEnvironment3D(
      id: id,
      name: name,
      position: position ?? vector.Vector3.zero(),
      plots: plots,
    );
  }

}

// ============ WORKSPACE STATE PROVIDER ============

/// Main workspace state provider - holds all application data
class WorkspaceState extends ChangeNotifier {
  
  // ============ CONSTANTS ============
  static const String defaultClusterId = 'apple-appl-zIMYTiw8eoQliUvygy4I';
  static const List<String> defaultVisibleTrends = [
    'accounts_payable',
    'accounts_receivable',
  ];

  // ============ FIREBASE ============
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ STATE ============
  
  // Loading states
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Current cluster
  ClusterData? _currentCluster;
  
  // Workspace clusters (can hold multiple clusters)
  final Map<String, ClusterData> _workspaceClusters = {};
  
  // Selected trend IDs
  final Set<String> _selectedTrendIds = {};
  
  // View mode
  ViewMode _viewMode = ViewMode.document;

  // ============ GETTERS ============
  
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ClusterData? get currentCluster => _currentCluster;
  Map<String, ClusterData> get workspaceClusters => Map.unmodifiable(_workspaceClusters);
  Set<String> get selectedTrendIds => Set.unmodifiable(_selectedTrendIds);
  ViewMode get viewMode => _viewMode;
  
  /// Get all trends from current cluster
  List<TrendData> get currentTrends => 
      _currentCluster?.trends.values.toList() ?? [];
  
  /// Get selected trends data
  List<TrendData> get selectedTrends => 
      currentTrends.where((t) => _selectedTrendIds.contains(t.id)).toList();
  
  /// Get visible trends (for visualization)
  List<TrendData> get visibleTrends =>
      currentTrends.where((t) => t.isVisible).toList();

  /// Get environments for visualization (converts all workspace clusters)
  List<GraphEnvironment3D> get environments {
    final envs = <GraphEnvironment3D>[];
    int index = 0;
    
    for (final cluster in _workspaceClusters.values) {
      envs.add(cluster.toEnvironment3D(
        position: vector.Vector3(index * 300.0, 0, 0),
      ));
      index++;
    }
    
    return envs;
  }

  /// Get current environment ID for selection
  String? get currentEnvironmentId => _currentCluster?.id;

  // ============ INITIALIZATION ============

  /// Initialize workspace with default cluster
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load the default cluster
      await loadCluster(defaultClusterId);
      
      // Set default visible trends
      if (_currentCluster != null) {
        for (final trendName in defaultVisibleTrends) {
          if (_currentCluster!.trends.containsKey(trendName)) {
            _currentCluster!.trends[trendName]!.isVisible = true;
            _currentCluster!.trends[trendName]!.isSelected = true;
            _selectedTrendIds.add(trendName);
          }
        }
        
        // Hide non-default trends initially
        for (final trend in _currentCluster!.trends.values) {
          if (!defaultVisibleTrends.contains(trend.id)) {
            trend.isVisible = false;
            trend.isSelected = false;
          }
        }
      }

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize workspace: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ============ CLUSTER MANAGEMENT ============

  /// Load a cluster by ID from Firestore
  Future<ClusterData?> loadCluster(String clusterId) async {
    try {
      final doc = await _firestore.collection('clusters').doc(clusterId).get();
      
      if (!doc.exists) {
        _errorMessage = 'Cluster not found: $clusterId';
        notifyListeners();
        return null;
      }

      final cluster = ClusterData.fromFirestore(doc);
      
      // Add to workspace
      _workspaceClusters[clusterId] = cluster;
      _currentCluster = cluster;
      
      notifyListeners();
      return cluster;
    } catch (e) {
      _errorMessage = 'Failed to load cluster: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Set the current active cluster
  void setCurrentCluster(String clusterId) {
    if (_workspaceClusters.containsKey(clusterId)) {
      _currentCluster = _workspaceClusters[clusterId];
      
      // Clear and reset selections for new cluster
      _selectedTrendIds.clear();
      
      notifyListeners();
    }
  }

  /// Remove a cluster from workspace
  void removeCluster(String clusterId) {
    _workspaceClusters.remove(clusterId);
    
    if (_currentCluster?.id == clusterId) {
      _currentCluster = _workspaceClusters.values.firstOrNull;
    }
    
    notifyListeners();
  }

  // ============ TREND MANAGEMENT ============

  /// Toggle trend selection
  void toggleTrendSelection(String trendId) {
    if (_currentCluster == null) return;
    
    final trend = _currentCluster!.trends[trendId];
    if (trend == null) return;

    if (_selectedTrendIds.contains(trendId)) {
      _selectedTrendIds.remove(trendId);
      trend.isSelected = false;
    } else {
      _selectedTrendIds.add(trendId);
      trend.isSelected = true;
    }

    notifyListeners();
  }

  /// Toggle trend visibility (show/hide in viz)
  void toggleTrendVisibility(String trendId) {
    if (_currentCluster == null) return;
    
    final trend = _currentCluster!.trends[trendId];
    if (trend == null) return;

    trend.isVisible = !trend.isVisible;
    notifyListeners();
  }

  /// Set trend visibility directly
  void setTrendVisibility(String trendId, bool visible) {
    if (_currentCluster == null) return;
    
    final trend = _currentCluster!.trends[trendId];
    if (trend == null) return;

    trend.isVisible = visible;
    notifyListeners();
  }

  /// Select multiple trends at once
  void selectTrends(List<String> trendIds) {
    _selectedTrendIds.clear();
    
    for (final id in trendIds) {
      if (_currentCluster?.trends.containsKey(id) == true) {
        _selectedTrendIds.add(id);
        _currentCluster!.trends[id]!.isSelected = true;
      }
    }
    
    notifyListeners();
  }

  /// Clear all selections
  void clearTrendSelections() {
    for (final trend in currentTrends) {
      trend.isSelected = false;
    }
    _selectedTrendIds.clear();
    notifyListeners();
  }

  /// Show all trends
  void showAllTrends() {
    for (final trend in currentTrends) {
      trend.isVisible = true;
    }
    notifyListeners();
  }

  /// Hide all trends
  void hideAllTrends() {
    for (final trend in currentTrends) {
      trend.isVisible = false;
    }
    notifyListeners();
  }

  /// Reorder trends (for UI drag & drop)
  void reorderTrends(int oldIndex, int newIndex) {
    if (_currentCluster == null) return;
    
    final keys = _currentCluster!.trends.keys.toList();
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final key = keys.removeAt(oldIndex);
    keys.insert(newIndex, key);
    
    // Note: Maps in Dart maintain insertion order, but we can't easily reorder them
    // This is a placeholder - in practice you might need a separate order list
    notifyListeners();
  }

  // ============ VIEW MANAGEMENT ============

  /// Set the current view mode
  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  /// Toggle between document and graph view
  void toggleView() {
    _viewMode = _viewMode == ViewMode.document 
        ? ViewMode.graph 
        : ViewMode.document;
    notifyListeners();
  }

  // ============ SEARCH ============

  /// Search clusters by name or tag
  Future<List<ClusterData>> searchClusters(String query) async {
    try {
      final queryLower = query.toLowerCase();
      final isTagSearch = query.startsWith('#');
      
      Query<Map<String, dynamic>> ref = _firestore.collection('clusters');
      
      if (isTagSearch) {
        final tag = query.substring(1);
        ref = ref.where('tags', arrayContains: tag);
      }
      
      final snapshot = await ref.limit(20).get();
      
      final results = snapshot.docs
          .map((doc) => ClusterData.fromFirestore(doc))
          .where((cluster) {
            if (!isTagSearch) {
              return cluster.name.toLowerCase().contains(queryLower) ||
                  cluster.ticker?.toLowerCase().contains(queryLower) == true;
            }
            return true;
          })
          .toList();
      
      return results;
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  // ============ UTILITY ============

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset workspace to initial state
  Future<void> reset() async {
    _isInitialized = false;
    _isLoading = false;
    _errorMessage = null;
    _currentCluster = null;
    _workspaceClusters.clear();
    _selectedTrendIds.clear();
    _viewMode = ViewMode.document;
    
    notifyListeners();
    
    // Re-initialize with defaults
    await initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }
}


// ============ VIEW MODE ENUM ============

enum ViewMode {
  document,
  graph,
}

extension ViewModeExtension on ViewMode {
  String get displayName {
    switch (this) {
      case ViewMode.document:
        return 'Document';
      case ViewMode.graph:
        return 'Graph';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ViewMode.document:
        return Icons.description;
      case ViewMode.graph:
        return Icons.bubble_chart;
    }
  }
}