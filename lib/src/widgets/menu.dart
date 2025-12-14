import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reorderables/reorderables.dart';
import '../../styles.dart';
import '../services/visualization_engine.dart';

enum MenuTab { environmentList, environment, cluster, explore }

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
        // Default fallback: go to environment list
        _currentTab = MenuTab.environmentList;
      }
    });
  }

  void _exitMenu() {
    // Navigate to homepage - adjust based on your navigation setup
    Navigator.of(context).pop();
    // or: Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
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
      child:

      // Container
      Expanded(

        // Here is where I put conditional logic to show what tab depending on click and passed info

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
          child: _buildCurrentTab(),
        ),

        // End of Conditional Tabs

      ),            
    );
  }

  // ========== TAB SWITCHER ==========
  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case MenuTab.environmentList:
        return _environmentListTab();
      case MenuTab.environment:
        return _environmentTab();
      case MenuTab.cluster:
        return _clusterTab();
      case MenuTab.explore:
        return _exploreTab();
    }
  }

  Widget _environmentListTab() { 
    return 
    // Content Column
    Column(
      children: [

        // Top Navigation
        Container(
          width: double.infinity, 
          padding:EdgeInsets.only(top:30, left:40, right:40, bottom:15,),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _exitMenu,
              ),
              Text(
                'Your Workspace',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.cyan,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Handle edit action
                },
              ),
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

            // Container: Pills and Bottom Button
            child: Column(
              children: [

                // Pill Content
                Expanded(
                  child: Container(
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
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  VisualizationEngineService.selectEnvironment(env);
                                  VisualizationEngineService.focusOnSelected();
                                });
                                _navigateTo(MenuTab.environment);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? Colors.cyan.withOpacity(0.1)
                                    : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected 
                                      ? Colors.cyan 
                                      : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Add drag handle icon
                                    Icon(
                                      Icons.drag_indicator,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      env.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                        color: isSelected 
                                          ? Colors.black 
                                          : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  
                ),

                // Bottom Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        final newEnv = VisualizationEngineService.addNewEnvironment();
                        VisualizationEngineService.addSampleDataToEnvironment(newEnv);
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Environment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );    
  }

  Widget _environmentTab() { 
    return 
    // Content Column
      Column(
          children: [

            // Top Navigation
            Container(
              width: double.infinity, 
              padding:EdgeInsets.only(top:30, left:40, right:40, bottom:15,),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _goBack,
                  ),
                  Text(
                    'Environment 1',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.cyan,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Handle edit action
                    },
                  ),
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

                // Container: Pills and Bottom Button
                child: Column(
                  children: [

                    // Pill Content
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        child: ReorderableWrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          alignment: WrapAlignment.start,
                          needsLongPressDraggable: false,
                          onReorder: (int oldIndex, int newIndex) {
                            // handle reorder later
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
                          children: [
                            ReorderableWidget(
                              reorderable: true,
                              key: const ValueKey('pill1'),
                              child: GestureDetector(
                                onTap: () {
                                  // handle tap
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    "test pill 1",
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                            ReorderableWidget(
                              reorderable: true,
                              key: const ValueKey('pill2'),
                              child: GestureDetector(
                                onTap: () {
                                  // handle tap
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    "test pill 2",
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      
                    ),

                    // Bottom Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigateTo(MenuTab.cluster);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New Data Cluster'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }

  Widget _clusterTab() {
    return
    // Content Column
    Column(
      children: [

        // Top Navigation
        Container(
          width: double.infinity, 
          padding: EdgeInsets.only(top: 30, left: 40, right: 40, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _goBack,
              ),
              Text(
                'Select Data Cluster',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 40), // Placeholder for symmetry
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

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Section 1: In Your Environment
                        Row(
                          children: [
                            const Text(
                              'In Your Environment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _buildClusterPill('Apple Trends'),
                            _buildClusterPill('US China Trade'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section 2: In Your Workspace
                        Row(
                          children: [
                            const Text(
                              'In Your Workspace',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _buildClusterPill('Apple Trends'),
                            _buildClusterPill('US China Trade'),
                            _buildClusterPill('US India Trade'),
                            _buildClusterPill('AI Innovation'),
                            _buildClusterPill('US GDP'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _navigateTo(MenuTab.explore);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Explore Data Clusters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

  }

  Widget _exploreTab() {
    // Dummy tags
    final List<String> tags = [
      'All Data Constellations',
      'Stock Comparisons',
      'Macro Trends',
      'US - Int Trade',
      'AI and Tech',
      'Market Movers',
      'US Socioeconomic Trends',
    ];

    // Dummy clusters (would come from Firebase)
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

    // Filter clusters based on search
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
      key: const ValueKey('exploreTab'),
      children: [
        // Top Navigation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 30, left: 40, right: 40, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _goBack,
              ),
              const Text(
                'Explore Data Clusters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.pinkAccent,
                ),
              ),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsList(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tags.map((tag) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _searchQuery = '#${tag.replaceAll(' ', '-')}';
              _searchController.text = _searchQuery;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.sell_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
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
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedClusters.remove(cluster['name']);
              } else {
                _selectedClusters.add(cluster['name']);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyan : const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cluster['name'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isSelected ? Icons.check : Icons.chevron_right,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClusterPill(String label) {
    return GestureDetector(
      onTap: () {
        // Handle pill tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

}