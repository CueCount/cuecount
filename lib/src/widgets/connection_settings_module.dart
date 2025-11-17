import 'package:flutter/material.dart';
import '../pages/connections_settings.dart';

class ConnectionSettingsModule extends StatelessWidget {
  const ConnectionSettingsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConnectionsSettingsPage()),
        );
      },
      child: Container(
        color: Colors.purple,
        child: const Center(
          child: Text(
            'Connection and Account Settings',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
