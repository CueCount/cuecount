import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../styles.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      height: MediaQuery.of(context).size.height - 135,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(60),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Toggle Bar
          Container(
            padding: const EdgeInsets.only(
              left: 40,
              right: 40,
              top: 40,
              bottom: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu,
                  size: 24,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 16),
                _buildToggleTab('Yours', false),
                const SizedBox(width: 16),
                _buildToggleTab('Current', true),
                const SizedBox(width: 16),
                _buildToggleTab('Explore', false),
              ],
            ),
          ),
          
          // Constellation Container with Pills Inside
          Expanded(
            child: Stack(
              children: [
                // LAYER 1 (Bottom): The border container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: const Color.fromARGB(255, 243, 243, 243),
                      width: 2,
                    ),
                  ),
                ),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Text(
                          'Apple Trends',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Subtitle Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'AAPL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Your View',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.cyan,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Explore',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Pills Section - Inside but scrollable
                  Expanded(
                    child: Container(
                      width: double.infinity, 
                      padding: const EdgeInsets.all(40),
                      
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.start,
                              children: [
                                _buildPill('AAPL', Icons.visibility_outlined, isPrimary: true),
                                _buildPill('Electronics Innovation', Icons.visibility_outlined, isPrimary: true),
                                _buildPill('US-China Trade', Icons.visibility_outlined, isPrimary: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),          
        ],
      ),
    );
  }
  
  Widget _buildToggleTab(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive ? Colors.cyan : Colors.grey.shade600,
      ),
    );
  }
  
  Widget _buildPill(String label, IconData? icon, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.shade600 : Colors.grey.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ],
          const SizedBox(width: 6),
          Icon(
            Icons.more_horiz,
            size: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}