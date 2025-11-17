import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/nav.dart';
import '../services/visualization_engine.dart';
import 'login_page.dart';

class VisualizationPage extends StatefulWidget {
  final String companyId;
  final String companyName;
  final List<String> documentIds;
  final User? user;

  const VisualizationPage({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.documentIds,
    this.user,
  });

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> {
  List<DocumentSnapshot>? _documents;
  bool _isLoading = true;
  String? _error;
  
  // UI Controls
  bool _showGrid = true;
  bool _showAxes = true;
  bool _showLabels = true;
  Set<String> _selectedFields = {};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      // Fetch all documents
      final futures = widget.documentIds.map((id) => 
        FirebaseFirestore.instance
          .collection('documents')
          .doc(id)
          .get()
      ).toList();
      
      final snapshots = await Future.wait(futures);
      
      // Sort documents by period
      snapshots.sort((a, b) {
        if (!a.exists || !b.exists) return 0;
        
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        final aPeriod = aData['period'] ?? '';
        final bPeriod = bData['period'] ?? '';
        
        final aMatch = RegExp(r'(\d{4})_Q(\d)').firstMatch(aPeriod.toString());
        final bMatch = RegExp(r'(\d{4})_Q(\d)').firstMatch(bPeriod.toString());
        
        if (aMatch == null || bMatch == null) return 0;
        
        final aYear = int.parse(aMatch.group(1)!);
        final bYear = int.parse(bMatch.group(1)!);
        final aQuarter = int.parse(aMatch.group(2)!);
        final bQuarter = int.parse(bMatch.group(2)!);
        
        if (aYear != bYear) {
          return bYear.compareTo(aYear);
        }
        
        return aQuarter.compareTo(bQuarter);
      });
      
      // Get available fields
      if (snapshots.isNotEmpty && snapshots.first.exists) {
        final sampleData = snapshots.first.data() as Map<String, dynamic>;
        final numericFields = sampleData.entries
            .where((e) => e.value is num)
            .map((e) => e.key)
            .toSet();
        
        setState(() {
          _selectedFields = numericFields;
        });
      }
      
      setState(() {
        _documents = snapshots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppNavBar(
        user: widget.user,
        onHome: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onLogin: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        },
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      drawer: SidebarMenu(
        user: widget.user,
        onHome: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onLogin: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
          );
        },
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      body: Stack(
        children: [
          // Main visualization area
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadDocuments();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_documents != null)
            VisualizationEngine(
              documents: _documents!,
              companyName: widget.companyName,
            ),
          
          // Control panel overlay
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.companyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.documentIds.length} documents',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  
                  // Visualization controls
                  const Text(
                    'Visualization Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: const Text(
                      'Show Grid',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    value: _showGrid,
                    onChanged: (value) {
                      setState(() {
                        _showGrid = value;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  SwitchListTile(
                    title: const Text(
                      'Show Axes',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    value: _showAxes,
                    onChanged: (value) {
                      setState(() {
                        _showAxes = value;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  SwitchListTile(
                    title: const Text(
                      'Show Labels',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    value: _showLabels,
                    onChanged: (value) {
                      setState(() {
                        _showLabels = value;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Field legend
                  const Text(
                    'Data Fields',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Simple color legend
                  _buildSimpleFieldLegend(),
                ],
              ),
            ),
          ),
          
          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back to Documents',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSimpleFieldLegend() {
    final colors = {
      'total_assets': Colors.green,
      'total_liabilities': Colors.red,
      'total_equity': Colors.blue,
      'net_income': Colors.orange,
      'revenue': Colors.purple,
      'cash': Colors.cyan,
    };
    
    return Column(
      children: colors.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}