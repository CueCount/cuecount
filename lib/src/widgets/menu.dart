import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reorderables/reorderables.dart';
import '../../styles.dart';
import '../services/visualization_engine.dart';
import 'pill_container.dart';
import 'pill_cluster.dart';
import 'pill_trend.dart';

enum MenuTab { environmentList, environment, explore }

// ========== TAB CONTENT DATA CLASS ==========
// Holds all the dynamic pieces that vary between tabs
class TabContent {
  final IconData leftIcon;
  final VoidCallback onLeftPressed;
  final String title;
  final Color titleColor;
  final IconData? rightIcon;          // null = no right button (shows empty SizedBox)
  final VoidCallback? onRightPressed;
  final Widget mainContent;           // The unique content for this tab
  final BottomButtonConfig? bottomButton; // null = no bottom button

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

// Config for the optional bottom button
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
  final dynamic vizState;
  
  const VisualizationMenu({
    super.key,
    this.user,
    required this.vizState,
  });

  @override
  State<VisualizationMenu> createState() => _VisualizationMenuState();
}

class _VisualizationMenuState extends State<VisualizationMenu> {

  MenuTab _currentTab = MenuTab.environment;
  final List<MenuTab> _history = [];
  String _searchQuery = '';
  List<String> _selectedClusters = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Track which sections are expanded (by section key)
  final Map<String, bool> _expandedSections = {
    'inYourEnvironment': true,
    'inYourWorkspace': true,
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
        _currentTab = MenuTab.environmentList;
      }
    });
  }

  void _exitMenu() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Get the dynamic content for the current tab
    final tabContent = _getTabContent();

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
        // ========== SHARED LAYOUT STRUCTURE ==========
        child: Column(
          key: ValueKey(_currentTab), // Important for AnimatedSwitcher
          children: [
            // ===== TOP NAVIGATION BAR =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 30, left: 40, right: 40, bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // Left Icon Button (dynamic)
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

                  // Title (dynamic)
                  Text(
                    tabContent.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: tabContent.titleColor,
                    ),
                  ),

                  // Right Icon Button (dynamic, or empty space if null)
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
                    const SizedBox(width: 40), // Placeholder for symmetry
                ],
              ),
            ),

            // ===== GREY CONTENT SECTION =====
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(60),
                ),

                // Inner column: main content + optional bottom button
                child: Column(
                  children: [
                    // Main Content Area (dynamic - fully customizable per tab)
                    Expanded(
                      child: tabContent.mainContent,
                    ),

                    // Bottom Button (conditional - only shows if config provided)
                    if (tabContent.bottomButton != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: tabContent.bottomButton!.onPressed,
                          icon: Icon(tabContent.bottomButton!.icon, size: 18),
                          label: Text(tabContent.bottomButton!.label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tabContent.bottomButton!.backgroundColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                tabContent.bottomButton!.borderRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== TAB CONTENT SWITCHER ==========
  TabContent _getTabContent() {
    switch (_currentTab) {
      case MenuTab.environmentList:
        return _environmentListContent();
      case MenuTab.environment:
        return _environmentContent();
      case MenuTab.explore:
        return _exploreContent();
    }
  }

  // ========== ENVIRONMENT LIST TAB ==========
  TabContent _environmentListContent() {
    return TabContent(
      leftIcon: Icons.chevron_left,
      onLeftPressed: _exitMenu,
      title: 'Your Workspace',
      titleColor: Colors.cyan,
      rightIcon: Icons.edit_outlined,
      onRightPressed: () {
        // Handle edit action
      },
      mainContent: _buildEnvironmentListMainContent(),
      bottomButton: BottomButtonConfig(
        label: 'Add New Environment',
        icon: Icons.add,
        backgroundColor: Colors.cyan,
        onPressed: () {
          setState(() {
            final newEnv = VisualizationEngineService.addNewEnvironment();
            VisualizationEngineService.addSampleDataToEnvironment(newEnv);
          });
        },
      ),
    );
  }

  Widget _buildEnvironmentListMainContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: ReorderableWrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.start,
        needsLongPressDraggable: false,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            VisualizationEngineService.reorderEnvironments(oldIndex, newIndex);
          });
        },
        buildDraggableFeedback: (context, constraint, widget) {
          return Material(
            elevation: 6.0,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: constraint,
              child: widget,
            ),
          );
        },
        children: VisualizationEngineService.environments.map((env) {
          final isSelected = env == VisualizationEngineService.selectedEnvironment;
          return ReorderableWidget(
            reorderable: true,
            key: ValueKey(env.id),
            child: EnvironmentPill(
              label: env.name,
              isSelected: isSelected,
              showDragHandle: true,
              onTap: () {
                setState(() {
                  VisualizationEngineService.selectEnvironment(env);
                  VisualizationEngineService.focusOnSelected();
                });
                _navigateTo(MenuTab.environment);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

 // ========== ENVIRONMENT TAB ==========
  TabContent _environmentContent() {
    return TabContent(
      leftIcon: Icons.chevron_left,
      onLeftPressed: _goBack,
      title: 'Environment 1',
      titleColor: Colors.cyan,
      rightIcon: Icons.edit_outlined,
      onRightPressed: () {
        // Handle edit action
      },
      mainContent: _buildEnvironmentMainContent(),
      bottomButton: BottomButtonConfig(
        label: 'Explore Data Clusters',
        icon: Icons.add,
        backgroundColor: Colors.pinkAccent,
        borderRadius: 30,
        onPressed: () {
          _navigateTo(MenuTab.explore);
        },
      ),
    );
  }

  Widget _buildEnvironmentMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Trends/Data in this Environment
          PillContainer(
            label: 'In Data Environment',
            reorderable: true,
            collapsed: !(_expandedSections['inDataEnvironment'] ?? true),
            onToggle: () => setState(() {
              _expandedSections['inDataEnvironment'] = 
                  !(_expandedSections['inDataEnvironment'] ?? true);
            }),
            onReorder: (oldIndex, newIndex) {
              // Handle reorder of trends
            },
            children: [
              ClusterPillOutline(
                label: "Assets",
                isSelected: true,
                showIcon: false,
                onTap: () {},
              ),
              ClusterPillOutline(
                label: "Liabilities",
                isSelected: true,
                showIcon: false,
                onTap: () {},
              ),
              ClusterPillOutline(
                label: "Equity",
                isSelected: true,
                showIcon: false,
                onTap: () {},
              ),
              ClusterPillOutline(
                label: "Net Balance",
                showIcon: false,
                onTap: () {},
              ),
              ClusterPillOutline(
                label: "Cash & Cash Equivalents",
                showIcon: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Add from Environment
          PillContainer(
            label: 'Add Data from Environment',
            reorderable: false,
            collapsed: !(_expandedSections['addFromEnvironment'] ?? true),
            onToggle: () => setState(() {
              _expandedSections['addFromEnvironment'] = 
                  !(_expandedSections['addFromEnvironment'] ?? true);
            }),
            children: [
              ClusterPill(label: 'Apple Trends', onTap: () {}),
              ClusterPill(label: 'US China Trade', onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),

          // Section 3: Add from Workspace
          PillContainer(
            label: 'Add Data from Workspace',
            reorderable: false,
            collapsed: !(_expandedSections['addFromWorkspace'] ?? true),
            onToggle: () => setState(() {
              _expandedSections['addFromWorkspace'] = 
                  !(_expandedSections['addFromWorkspace'] ?? true);
            }),
            children: [
              ClusterPill(label: 'Apple Trends', onTap: () {}),
              ClusterPill(label: 'US China Trade', onTap: () {}),
              ClusterPill(label: 'US India Trade', onTap: () {}),
              ClusterPill(label: 'AI Innovation', onTap: () {}),
              ClusterPill(label: 'US GDP', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
  
  // ========== EXPLORE TAB ==========
  TabContent _exploreContent() {
    return TabContent(
      leftIcon: Icons.chevron_left,
      onLeftPressed: _goBack,
      title: 'Explore Data Clusters',
      titleColor: Colors.pinkAccent,
      rightIcon: null, // No right button
      onRightPressed: null,
      mainContent: _buildExploreMainContent(),
      bottomButton: null, // No bottom button for this tab
    );
  }

  Widget _buildExploreMainContent() {
    final List<String> tags = [
      'All Data Constellations',
      'Stock Comparisons',
      'Macro Trends',
      'US - Int Trade',
      'AI and Tech',
      'Market Movers',
      'US Socioeconomic Trends',
    ];

    final List<Map<String, dynamic>> allClusters = [
      {'name': 'APPL', 'tags': ['Stock Comparisons']},
      {'name': 'US-China Trade', 'tags': ['Stock Comparisons', 'US - Int Trade']},
      {'name': 'AI Innovation', 'tags': ['AI and Tech']},
      {'name': 'US-India Trade', 'tags': ['US - Int Trade']},
      {'name': 'NVDIA', 'tags': ['Stock Comparisons', 'AI and Tech']},
      {'name': 'US GDP', 'tags': ['Macro Trends']},
      {'name': 'Electronics Innovation', 'tags': ['AI and Tech']},
      {'name': 'MSFT', 'tags': ['Stock Comparisons']},
    ];

    final filteredClusters = _searchQuery.isEmpty
        ? <Map<String, dynamic>>[]
        : allClusters.where((c) {
            final searchLower = _searchQuery.toLowerCase().replaceAll('#', '');
            final nameMatch = c['name'].toLowerCase().contains(searchLower);
            final tagMatch = (c['tags'] as List).any(
              (tag) => tag.toLowerCase().contains(searchLower),
            );
            return nameMatch || tagMatch;
          }).toList();

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
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: Icon(Icons.close, color: Colors.grey.shade500, size: 20),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Content: Tags or Search Results
        Expanded(
          child: SingleChildScrollView(
            child: _searchQuery.isEmpty
                ? _buildTagsList(tags)
                : _buildClusterResults(filteredClusters),
          ),
        ),
      ],
    );
  }

  // ========== HELPER WIDGETS ==========

  Widget _buildTagsList(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags.map((tag) {
        return TrendTagPill(
          label: tag,
          onTap: () {
            setState(() {
              _searchQuery = '#${tag.replaceAll(' ', '-')}';
              _searchController.text = _searchQuery;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildClusterResults(List<Map<String, dynamic>> clusters) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: clusters.map((cluster) {
        final isSelected = _selectedClusters.contains(cluster['name']);
        return ClusterPill(
          label: cluster['name'],
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedClusters.remove(cluster['name']);
              } else {
                _selectedClusters.add(cluster['name']);
              }
            });
          },
        );
      }).toList(),
    );
  }

}