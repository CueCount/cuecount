import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import '../../styles.dart';
import '../providers/workspaceState.dart';
import 'pill_container.dart';
import 'pill_cluster.dart';
import 'pill_trend.dart';

enum MenuTab { clusterList, cluster, explore }

// ========== TAB CONTENT DATA CLASS ==========
class TabContent {
  final IconData leftIcon;
  final VoidCallback onLeftPressed;
  final String title;
  final Color titleColor;
  final IconData? rightIcon;
  final VoidCallback? onRightPressed;
  final Widget mainContent;
  final BottomButtonConfig? bottomButton;

  const TabContent({
    required this.leftIcon,
    required this.onLeftPressed,
    required this.title,
    required this.titleColor,
    this.rightIcon,
    this.onRightPressed,
    required this.mainContent,
    this.bottomButton,
  });
}

class BottomButtonConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double borderRadius;

  const BottomButtonConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.borderRadius = 10,
  });
}

class VisualizationMenu extends StatefulWidget {
  final User? user;
  
  const VisualizationMenu({
    super.key,
    this.user,
  });

  @override
  State<VisualizationMenu> createState() => _VisualizationMenuState();
}

class _VisualizationMenuState extends State<VisualizationMenu> {

  MenuTab _currentTab = MenuTab.cluster;
  final List<MenuTab> _history = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Search state
  List<ClusterData> _searchResults = [];
  bool _isSearching = false;
  
  // Track which sections are expanded
  final Map<String, bool> _expandedSections = {
    'inYourCluster': true,
    'addFromWorkspace': true,
  };

  void _navigateTo(MenuTab tab) {
    setState(() {
      _history.add(_currentTab);
      _currentTab = tab;
    });
  }

  void _goBack() {
    setState(() {
      if (_history.isNotEmpty) {
        _currentTab = _history.removeLast();
      } else {
        _currentTab = MenuTab.clusterList;
      }
    });
  }

  void _exitMenu() {
    Navigator.of(context).pop();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final workspace = Provider.of<WorkspaceState>(context, listen: false);
      final results = await workspace.searchClusters(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _navigateToCluster(String clusterId) async {
    final workspace = Provider.of<WorkspaceState>(context, listen: false);
    
    try {
      await workspace.loadCluster(clusterId);
      _navigateTo(MenuTab.cluster);
    } catch (e) {
      print('Error loading cluster: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceState>(
      builder: (context, workspace, child) {
        final tabContent = _getTabContent(workspace);

        return Container(
          width: 420,
          height: MediaQuery.of(context).size.height - 135,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: const Color.fromARGB(255, 243, 243, 243),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey(_currentTab),
              children: [
                // Top Navigation Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 30, left: 40, right: 40, bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          tabContent.leftIcon,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: tabContent.onLeftPressed,
                      ),
                      Text(
                        tabContent.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: tabContent.titleColor,
                        ),
                      ),
                      if (tabContent.rightIcon != null)
                        IconButton(
                          icon: Icon(
                            tabContent.rightIcon,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: tabContent.onRightPressed,
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Grey Content Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: tabContent.mainContent),
                        if (tabContent.bottomButton != null) ...[
                          const SizedBox(height: 20),
                          _buildBottomButton(tabContent.bottomButton!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(BottomButtonConfig config) {
    return GestureDetector(
      onTap: config.onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(config.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              config.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TabContent _getTabContent(WorkspaceState workspace) {
    switch (_currentTab) {
      case MenuTab.clusterList:
        return _clusterListContent(workspace);
      case MenuTab.cluster:
        return _clusterContent(workspace);
      case MenuTab.explore:
        return _exploreContent(workspace);
    }
  }

  // ========== CLUSTER LIST TAB ==========
  TabContent _clusterListContent(WorkspaceState workspace) {
    return TabContent(
      leftIcon: Icons.close,
      onLeftPressed: _exitMenu,
      title: 'Your Clusters',
      titleColor: Colors.black87,
      rightIcon: Icons.settings,
      onRightPressed: () {},
      mainContent: _buildClusterListMainContent(workspace),
      bottomButton: BottomButtonConfig(
        label: 'Add New Cluster',
        icon: Icons.add,
        backgroundColor: Colors.cyan,
        borderRadius: 30,
        onPressed: () => _navigateTo(MenuTab.explore),
      ),
    );
  }

  Widget _buildClusterListMainContent(WorkspaceState workspace) {
    final clusters = workspace.workspaceClusters.values.toList();
    
    if (clusters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No clusters in workspace',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: clusters.map((cluster) {
          final isSelected = cluster.id == workspace.currentCluster?.id;
          return ClusterPill(
            label: cluster.name,
            isSelected: isSelected,
            onTap: () {
              workspace.setCurrentCluster(cluster.id);
              _navigateTo(MenuTab.cluster);
            },
          );
        }).toList(),
      ),
    );
  }

  // ========== CLUSTER TAB (WITH TRENDS FROM WORKSPACE) ==========
  TabContent _clusterContent(WorkspaceState workspace) {
    final clusterName = workspace.currentCluster?.name ?? 'Cluster';
    
    return TabContent(
      leftIcon: Icons.chevron_left,
      onLeftPressed: _goBack,
      title: clusterName,
      titleColor: Colors.cyan,
      rightIcon: Icons.more_horiz,
      onRightPressed: () {},
      mainContent: _buildClusterMainContent(workspace),
      bottomButton: BottomButtonConfig(
        label: 'Explore Data Clusters',
        icon: Icons.add,
        backgroundColor: Colors.pinkAccent,
        borderRadius: 30,
        onPressed: () => _navigateTo(MenuTab.explore),
      ),
    );
  }

  Widget _buildClusterMainContent(WorkspaceState workspace) {
    if (workspace.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workspace.currentCluster == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No cluster selected',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _navigateTo(MenuTab.explore),
              child: const Text('Explore clusters'),
            ),
          ],
        ),
      );
    }

    // Get trends from current cluster via WorkspaceState
    final trends = workspace.currentTrends;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Trends in this Cluster
          PillContainer(
            label: 'Trends in Cluster',
            reorderable: true,
            collapsed: !(_expandedSections['inYourCluster'] ?? true),
            onToggle: () => setState(() {
              _expandedSections['inYourCluster'] = 
                  !(_expandedSections['inYourCluster'] ?? true);
            }),
            onReorder: (oldIndex, newIndex) {
              workspace.reorderTrends(oldIndex, newIndex);
            },
            children: trends.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No trends in this cluster',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ]
                : trends.map((trend) {
                    return TrendPill(
                      label: trend.displayName,
                      color: trend.color,
                      isVisible: trend.isVisible,
                      isSelected: trend.isSelected,
                      onTap: () {
                        // Toggle visibility when tapped
                        workspace.toggleTrendVisibility(trend.id);
                      },
                      onVisibilityToggle: () {
                        workspace.toggleTrendVisibility(trend.id);
                      },
                    );
                  }).toList(),
          ),
          const SizedBox(height: 24),

          // Section 2: Add from Workspace
          PillContainer(
            label: 'Other Clusters in Workspace',
            reorderable: false,
            collapsed: !(_expandedSections['addFromWorkspace'] ?? true),
            onToggle: () => setState(() {
              _expandedSections['addFromWorkspace'] = 
                  !(_expandedSections['addFromWorkspace'] ?? true);
            }),
            children: workspace.workspaceClusters.values
                .where((c) => c.id != workspace.currentCluster?.id)
                .map((cluster) {
                  return ClusterPill(
                    label: cluster.name,
                    onTap: () {
                      workspace.setCurrentCluster(cluster.id);
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
  
  // ========== EXPLORE TAB ==========
  TabContent _exploreContent(WorkspaceState workspace) {
    return TabContent(
      leftIcon: Icons.chevron_left,
      onLeftPressed: _goBack,
      title: 'Explore Data Clusters',
      titleColor: Colors.pinkAccent,
      rightIcon: null,
      onRightPressed: null,
      mainContent: _buildExploreMainContent(workspace),
      bottomButton: null,
    );
  }

  Widget _buildExploreMainContent(WorkspaceState workspace) {
    final List<String> tags = [
      'All Data Constellations',
      'Stock Comparisons',
      'Macro Trends',
      'US - Int Trade',
      'AI and Tech',
      'Market Movers',
      'US Socioeconomic Trends',
    ];

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _performSearch(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or #tag',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_isSearching)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                      _searchResults = [];
                      _searchController.clear();
                    });
                  },
                  child: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Content: Tags (when empty) or Search Results
        Expanded(
          child: SingleChildScrollView(
            child: _searchQuery.isEmpty
                ? _buildTagsList(tags)
                : _buildClusterResults(_searchResults),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsList(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags.map((tag) {
        return TrendTagPill(
          label: tag,
          onTap: () {
            final tagQuery = '#$tag';
            setState(() {
              _searchQuery = tagQuery;
              _searchController.text = tagQuery;
            });
            _performSearch(tagQuery);
          },
        );
      }).toList(),
    );
  }

  Widget _buildClusterResults(List<ClusterData> clusters) {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (clusters.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No clusters found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.startsWith('#') 
                    ? 'Try a different tag'
                    : 'Try a different search term',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: clusters.map((cluster) {
        final workspace = Provider.of<WorkspaceState>(context, listen: false);
        final isInWorkspace = workspace.workspaceClusters.containsKey(cluster.id);
        
        return ClusterPill(
          label: cluster.name,
          isSelected: isInWorkspace,
          onTap: () {
            _navigateToCluster(cluster.id);
          },
        );
      }).toList(),
    );
  }
}