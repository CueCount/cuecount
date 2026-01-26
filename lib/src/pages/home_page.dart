import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import '../../styles.dart';
import 'visualization.dart';

class HomePage extends StatelessWidget {
  final User? user;
  const HomePage({super.key, this.user});
  bool get _isLoggedIn => user != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildLandingBody(context),
    );
  }

  Widget _buildLandingBody(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 60,
                color: AppColors.white,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Headline
            Text(
              'Welcome to Your Portfolio',
              style: AppTextStyles.large.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Body text
            Text(
              'Visualize your investments and track your portfolio performance with our powerful constellation visualization tools. Get insights into your financial journey and make informed decisions.',
              style: AppTextStyles.subMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // CTA Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Login/Account Button
                _buildCTAButton(
                  context: context,
                  label: _isLoggedIn ? 'My Account' : 'Login',
                  isPrimary: false,
                  onPressed: () {
                    if (_isLoggedIn) {
                      // Navigate to account/dashboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigate to account page'),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    }
                  },
                ),
                
                const SizedBox(width: 16),
                
                // Visualization Button
                _buildCTAButton(
                  context: context,
                  label: 'View Visualization',
                  isPrimary: false,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VisualizationPage(user: user),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 80), // Bottom spacing
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton({
    required BuildContext context,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : AppColors.white,
        foregroundColor: isPrimary ? AppColors.white : AppColors.primary,
        elevation: isPrimary ? 8 : 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isPrimary 
            ? BorderSide.none 
            : const BorderSide(color: AppColors.primary, width: 2),
        ),
        shadowColor: isPrimary ? AppColors.primary.withOpacity(0.4) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(
          color: isPrimary ? AppColors.white : AppColors.primary,
        ),
      ),
    );
  }
}