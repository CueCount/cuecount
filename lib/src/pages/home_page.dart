import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/nav.dart';
import 'login_page.dart';
import '../widgets/overall_portfolio_module.dart';
import '../widgets/saved_sub_constellations_module.dart';
import '../widgets/data_module.dart';
import '../widgets/quick_upload_module.dart';
import '../widgets/connection_settings_module.dart';


class HomePage extends StatelessWidget {
  final User? user;
  const HomePage({super.key, this.user});
  bool get _isLoggedIn => user != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(
        user: user,
        onHome: () {
          // Already on home - you can add scroll-to-top or other behavior later
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
        },
      ),

      drawer: SidebarMenu(
        user: user,
        onHome: () {
          // Here you could navigate to your actual home route if needed
          // For now, we're already on Home, so do nothing.
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
        },
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Then in your build method:
          // Top row: 2 big modules
          Expanded(
            flex: 2,
            child: Row(
              children: const [
                Expanded(child: OverallPortfolioModule()),
                SizedBox(width: 16),
                Expanded(child: SavedSubConstellationsModule()),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bottom row: 3 modules
          Expanded(
            flex: 1,
            child: Row(
              children: const [
                Expanded(child: DataModule()),
                SizedBox(width: 16),
                Expanded(child: QuickUploadModule()),
                SizedBox(width: 16),
                Expanded(child: ConnectionSettingsModule()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
