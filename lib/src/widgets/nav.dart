import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Top navigation bar
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final VoidCallback onHome;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const AppNavBar({
    super.key,
    required this.user,
    required this.onHome,
    required this.onLogin,
    required this.onLogout,
  });

  bool get _isLoggedIn => user != null;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_isLoggedIn ? 'Dashboard' : 'Dashboard (Guest)'),
      leading: IconButton(
        icon: const Icon(Icons.home),
        onPressed: onHome,
      ),
      actions: [
        // Login / Logout action (optional)
        TextButton(
          onPressed: _isLoggedIn ? onLogout : onLogin,
          child: Text(
            _isLoggedIn ? 'Logout' : 'Login',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        // Menu button in top-right that opens the left drawer
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Slide-in sidebar menu (Drawer)
class SidebarMenu extends StatelessWidget {
  final User? user;
  final VoidCallback onHome;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const SidebarMenu({
    super.key,
    required this.user,
    required this.onHome,
    required this.onLogin,
    required this.onLogout,
  });

  bool get _isLoggedIn => user != null;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Home
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop(); // close drawer
                onHome();
              },
            ),

            // Login / Logout
            ListTile(
              leading: Icon(_isLoggedIn ? Icons.logout : Icons.login),
              title: Text(_isLoggedIn ? 'Logout' : 'Login'),
              onTap: () {
                Navigator.of(context).pop(); // close drawer
                if (_isLoggedIn) {
                  onLogout();
                } else {
                  onLogin();
                }
              },
            ),

            // Settings (no link yet)
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              // No onTap for now - placeholder
            ),
          ],
        ),
      ),
    );
  }
}
